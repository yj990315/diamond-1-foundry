// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "diamond-facets/DiamondLoupeFacet.sol";
import "diamond-facets/OwnershipFacet.sol";
import "diamond-facets/DiamondCutFacet.sol";
import "scripts/DeployDiamond.sol";
import "test-facets/Test1Facet.sol";
import "test-facets/Test2Facet.sol";
import "test-facets/CacheBugTestFacet.sol";

abstract contract TestHelper is Test {
    address internal immutable DIAMOND_OWNER;
    uint256 internal immutable STANDARD_FACET_COUNT;
    address internal immutable TEST1_FACET_ADDR;
    address internal immutable TEST2_FACET_ADDR;
    address internal immutable DEFAULT_EOA;
    address internal immutable CACHE_BUG_TEST_FACET_ADDR;

    address[] internal deployedContracts;
    address internal cutFacetAddress;
    address internal diamondAddress;
    address internal initContractAddress;
    address internal loupeFacetAddress;
    address internal ownershipFacetAddress;
    DeployDiamond internal deployDiamondScript;
    IDiamondCut.FacetCut[] facetCuts;

    bytes4[] internal cutFacetSelectors = [
        DiamondCutFacet.diamondCut.selector
    ];
    
    bytes4[] internal loupeFacetSelectors = [
        DiamondLoupeFacet.facets.selector, 
        DiamondLoupeFacet.facetFunctionSelectors.selector,
        DiamondLoupeFacet.facetAddresses.selector,
        DiamondLoupeFacet.facetAddress.selector,
        DiamondLoupeFacet.supportsInterface.selector
    ];

    bytes4[] internal ownershipFacetSelectors = [
        OwnershipFacet.transferOwnership.selector, 
        OwnershipFacet.owner.selector
    ];

    bytes4[] internal test1FacetSelectors = [
        Test1Facet.Func1Test1.selector, 
        Test1Facet.Func2Test1.selector,
        Test1Facet.Func3Test1.selector
    ];

    bytes4[] internal test1FacetSelectorsWithSupportsInterface = [
        Test1Facet.supportsInterface.selector,
        Test1Facet.Func1Test1.selector, 
        Test1Facet.Func2Test1.selector,
        Test1Facet.Func3Test1.selector
    ];

    bytes4[] internal cacheBugFacetSelectors = [
        CacheBugTestFacet.cacheBugFunc1.selector, 
        CacheBugTestFacet.cacheBugFunc2.selector,
        CacheBugTestFacet.cacheBugFunc3.selector,
        CacheBugTestFacet.cacheBugFunc4.selector,
        CacheBugTestFacet.cacheBugFunc5.selector,
        CacheBugTestFacet.cacheBugFunc6.selector,
        CacheBugTestFacet.cacheBugFunc7.selector,
        CacheBugTestFacet.cacheBugFunc8.selector,
        CacheBugTestFacet.cacheBugFunc9.selector,
        CacheBugTestFacet.cacheBugFunc10.selector
    ];

    bytes4[] internal test1FacetSupportsInterfaceSelector = [
        Test1Facet.supportsInterface.selector
    ];

    bytes4[] internal test2FacetSelectors = [
        Test2Facet.Func1Test2.selector, 
        Test2Facet.Func2Test2.selector,
        Test2Facet.Func3Test2.selector,
        Test2Facet.Func4Test2.selector
    ];

    constructor() {
        DIAMOND_OWNER = address(0x2535);
        STANDARD_FACET_COUNT = 3;
        TEST1_FACET_ADDR = address(new Test1Facet());
        TEST2_FACET_ADDR = address(new Test2Facet());
        DEFAULT_EOA = address(0xDeFa);
        CACHE_BUG_TEST_FACET_ADDR = address(new CacheBugTestFacet());
    }


    /// DIAMOND HELPER FUNCTIONS ///

    function _getFacetSelectors(address facetAddress) internal returns(bytes4[] memory _facetFunctionSelectors) {
        (bool success, bytes memory data) = diamondAddress.call(
            abi.encodeWithSelector(DiamondLoupeFacet.facetFunctionSelectors.selector, facetAddress)
        );

        require(success, "TEST_DIAMOND::CALL_FAILED");

        _facetFunctionSelectors = abi.decode(data, (bytes4[]));
    }

    function _getFacetByFunctionSelector(bytes4 functionSelector) internal returns(address _facetAddress) {
         (bool success, bytes memory data) = diamondAddress.call(
            abi.encodeWithSelector(DiamondLoupeFacet.facetAddress.selector, functionSelector)
        );

        require(success, "TEST_DIAMOND::CALL_FAILED");

        _facetAddress = abi.decode(data, (address));
    }
}