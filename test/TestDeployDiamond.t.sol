// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "scripts/DeployDiamond.sol";
import "./TestHelper.sol";


contract DeployDiamondTest is TestHelper {
    function setUp() public {
        deployDiamondScript = new DeployDiamond();
        deployedContracts = deployDiamondScript.run();
        // See trace for Diamond revert errors: forge test -vvv
    }

    function testDeployDiamond() public {
        for (uint256 i; i < deployedContracts.length; ++i) {
            assertTrue(deployedContracts[i] != address(0));
        }
    }
}
