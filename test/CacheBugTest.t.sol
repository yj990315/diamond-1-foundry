// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "scripts/DeployDiamond.sol";
import "./TestHelper.sol";

contract CacheBugTest is TestHelper {
    function setUp() public {
        deployDiamondScript = new DeployDiamond();
        deployedContracts = deployDiamondScript.run();
        diamondAddress = deployedContracts[1];
    }

    function testShouldNotExhibitCacheBug() public {
        bool success;
        bytes4[] memory selectorsToRemove = new bytes4[](3);
        selectorsToRemove[0] = ownershipFacetSelectors[1];
        selectorsToRemove[1] = cacheBugFacetSelectors[4];
        selectorsToRemove[2] = cacheBugFacetSelectors[9];

        /// Add all CacheBugTestFacet selectors.
        facetCuts.push(IDiamondCut.FacetCut({
            facetAddress: CACHE_BUG_TEST_FACET_ADDR,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: cacheBugFacetSelectors
        }));

        vm.prank(DIAMOND_OWNER);
        (success, ) = diamondAddress.call(
            abi.encodeWithSelector(
                IDiamondCut.diamondCut.selector, 
                facetCuts,
                address(0),
                bytes('')
            )
        );

        assertTrue(success, "TEST_DIAMOND::CALL_FAILED");
        
        /// Remove owner() selector from OwnerShipFacet & some CacheBugTestFacet selectors.
        delete facetCuts;
        facetCuts.push(IDiamondCut.FacetCut({
            facetAddress: address(0),
            action: IDiamondCut.FacetCutAction.Remove,
            functionSelectors: selectorsToRemove
        }));

        vm.prank(DIAMOND_OWNER);
        (success, ) = diamondAddress.call(
            abi.encodeWithSelector(
                IDiamondCut.diamondCut.selector,
                facetCuts,
                address(0),
                bytes('')
            )
        );

        assertTrue(success, "TEST_DIAMOND::CALL_FAILED");

        bytes4[] memory loupeCacheBugFacetSelectors = _getFacetSelectors(CACHE_BUG_TEST_FACET_ADDR);
        assertEq(loupeCacheBugFacetSelectors.length, cacheBugFacetSelectors.length - 2);

        for (uint256 i; i < loupeCacheBugFacetSelectors.length; i++) {
            bytes4 selector = loupeCacheBugFacetSelectors[i];
            assertTrue(
                selector != selectorsToRemove[0]
                && selector != selectorsToRemove[1]
                && selector != selectorsToRemove[2]
            );
        }
    }
}
