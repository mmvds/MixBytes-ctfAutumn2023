// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract TWAPOracle {
    uint public constant min = 1 minutes;
    uint public constant MAX_LENGTH = 100;
    uint public immutable length;
    address public immutable pair;
    uint[MAX_LENGTH] public ticks;
    uint public round;
    uint public lastUpdated;

    constructor(uint _length, address _pair) {
        require(_length < MAX_LENGTH, "big len");
        length = _length;
        pair = _pair;
    }

    function update() external {
        if (lastUpdated != 0 && block.timestamp < lastUpdated + 5 * min) return;

        uint price = _getPoolPrice();

        uint tickIndex = round % length;
        ticks[tickIndex] = price;
        round++;
        lastUpdated = block.timestamp;
    }

    function _getPoolPrice() internal view returns (uint) {
        (uint stableCount, uint assetCount, ) = IUniswapV2Pair(pair)
            .getReserves();
        return (1e18 * stableCount) / assetCount;
    }

    function getPrice() public view returns (uint) {
        uint avg = 0;
        if (round == 0) return 0;
        uint tickIndex = (round - 1) % length;
        uint samples = tickIndex + 1;
        for (int i = int(tickIndex); i >= 0; i--) {
            avg += ticks[uint(i)]; // * weight (if oracle uses weighted averages)
        }

        if (round >= length) {
            samples = length;
            for (int i = int(length - 1); i >= int(tickIndex); i--) {
                avg += ticks[uint(i)]; // * weight (if oracle uses weighted averages)
            }
        }
        return avg / samples;
    }
}

contract SimpleToken is ERC20, Ownable {
    constructor(string memory name) ERC20(name, name) {}

    function mint(address to, uint amount) external onlyOwner {
        _mint(to, amount);
    }
}

contract Totalizator {
    uint public constant ROUND_INTERVAL = 1 hours;
    TWAPOracle public immutable oracle;

    uint public round;
    uint public totalDepositedUp;
    uint public totalDepositedDown;
    uint public start;
    uint public price;
    uint public finalPrice;

    address public immutable btc;
    address public immutable usdt;
    address public immutable token;

    mapping(uint => mapping(address => uint)) userUp;
    mapping(uint => mapping(address => uint)) userDown;

    constructor(address pool, address _token, address _btc, address _usdt) {
        oracle = new TWAPOracle(5, pool);
        token = _token;
        btc = _btc;
        usdt = _usdt;
    }

    function newRound() external {
        require(
            start == 0 ||
                (start > 0 &&
                    start + (ROUND_INTERVAL * 3) / 2 < block.timestamp),
            "!bid"
        );

        oracle.update();

        round++;
        price = oracle.getPrice();
        finalPrice = 0;
        start = block.timestamp;
        totalDepositedUp = 0;
        totalDepositedDown = 0;
    }

    function deposit(uint amount, bool up) external payable {
        require(
            start > 0 &&
                block.timestamp > start &&
                block.timestamp < start + ROUND_INTERVAL / 4,
            "!bid"
        );

        oracle.update();

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        if (up) {
            require(userDown[round][msg.sender] == 0, "only_up");
            userUp[round][msg.sender] += amount;
            totalDepositedUp += amount;
        } else {
            require(userUp[round][msg.sender] == 0, "only_down");
            userDown[round][msg.sender] += amount;
            totalDepositedDown += amount;
        }
    }

    function claim() external payable {
        require(start > 0, "!round");
        require(start + ROUND_INTERVAL < block.timestamp, "!finished");

        oracle.update();

        if (finalPrice == 0) {
            finalPrice = oracle.getPrice();
        }

        uint upUserDeposit = userUp[round][msg.sender];
        uint downUserDeposit = userDown[round][msg.sender];

        // price has be out of 0.1% range
        require(
            totalDepositedUp + totalDepositedDown > 0 &&
                ((upUserDeposit > 0 && finalPrice >= (price * 1001) / 1000) ||
                    (downUserDeposit > 0 &&
                        finalPrice <= (price * 999) / 1000)),
            "!winner"
        );

        userUp[round][msg.sender] = 0;
        userDown[round][msg.sender] = 0;
        if (upUserDeposit > 0) {
            uint prize = (IERC20(token).balanceOf(address(this)) *
                upUserDeposit) / totalDepositedUp;
            IERC20(token).transfer(msg.sender, prize);
        } else {
            uint prize = (IERC20(token).balanceOf(address(this)) *
                downUserDeposit) / totalDepositedDown;
            IERC20(token).transfer(msg.sender, prize);
        }
    }
}
