// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../contracts/SimpleDEX.sol";

contract DeployProxy {
    function deploy() public returns (address) {
        SimpleDEX dex = new SimpleDEX();
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(dex),
            msg.sender,
            abi.encodeWithSelector(SimpleDEX.initialize.selector, address(0), address(0))
        );
        return address(proxy);
    }
}