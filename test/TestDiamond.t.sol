// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "scripts/DeployDiamond.sol";
import "./TestHelper.sol";

contract TestDiamond is TestHelper {
    function setUp() public {
        deployDiamondScript = new DeployDiamond();
        deployedContracts = deployDiamondScript.run();
        cutFacetAddress = deployedContracts[0];
        diamondAddress = deployedContracts[1];
        initContractAddress = deployedContracts[2]; 
        loupeFacetAddress = deployedContracts[3];
        ownershipFacetAddress = deployedContracts[4];
        
        if (facetCuts.length != 0) {
            delete facetCuts;
        }
    }

    function testDiamondHasValidStandardFacetCount() public {
        (bool success, bytes memory data) = diamondAddress.call(abi.encode(IDiamondLoupe.facetAddresses.selector));

        assertTrue(success, "TEST_DIAMOND::CALL_FAILED");

        address[] memory facetAddresses = abi.decode(data, (address[]));

        assertEq(STANDARD_FACET_COUNT, facetAddresses.length);
    }

    function testDiamondHasValidDiamondCutFacetFunctionSelectors() public {
        assertEq(
            keccak256(abi.encode(_getFacetSelectors(cutFacetAddress))), 
            keccak256(abi.encode(cutFacetSelectors))
        );
    }

    function testDiamondHasValidLoupeFacetFunctionSelectors() public {
        assertEq(
            keccak256(abi.encode(_getFacetSelectors(loupeFacetAddress))), 
            keccak256(abi.encode(loupeFacetSelectors))
        );
    }

    function testDiamondHasValidOwnershipFacetFunctionSelectors() public {
        assertEq(
            keccak256(abi.encode(_getFacetSelectors(ownershipFacetAddress))), 
            keccak256(abi.encode(ownershipFacetSelectors))
        );
    }

    function testSelectorsAreCorrectlyAssociatedToDiamondCutFacet() public {
        assertEq(
            _getFacetByFunctionSelector(DiamondCutFacet.diamondCut.selector), 
            cutFacetAddress
        );
    }

    function testSelectorsAreCorrectlyAssociatedToLoupeFacet() public {
        assertEq(
            _getFacetByFunctionSelector(DiamondLoupeFacet.facets.selector), 
            loupeFacetAddress
        );
        assertEq(
            _getFacetByFunctionSelector(DiamondLoupeFacet.facetFunctionSelectors.selector), 
            loupeFacetAddress
        );
        assertEq(
            _getFacetByFunctionSelector(DiamondLoupeFacet.facetAddresses.selector), 
            loupeFacetAddress
        );
        assertEq(
            _getFacetByFunctionSelector(DiamondLoupeFacet.facetAddress.selector), 
            loupeFacetAddress
        );
        assertEq(
            _getFacetByFunctionSelector(DiamondLoupeFacet.supportsInterface.selector), 
            loupeFacetAddress
        );
    }

    function testSelectorsAreCorrectlyAssociatedToOwnershipFacet() public {
        assertEq(
            _getFacetByFunctionSelector(OwnershipFacet.owner.selector), 
            ownershipFacetAddress
        );
        assertEq(
            _getFacetByFunctionSelector(OwnershipFacet.transferOwnership.selector), 
            ownershipFacetAddress
        );
    }

    function testAddAllFacet1FunctionSelectorsAndCall() public {
        bool success;
        bytes memory data;

        facetCuts.push(IDiamondCut.FacetCut({
            facetAddress: TEST1_FACET_ADDR,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: test1FacetSelectors
        }));

        vm.expectEmit(true, true, false, true);
        emit LibDiamond.DiamondCut(facetCuts, address(0), bytes(''));

        // Diamond Cut
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

        // Test Facet add and facet function selectors matching
        (success, data) = diamondAddress.call(abi.encode(IDiamondLoupe.facetAddresses.selector));
        
        assertTrue(success, "TEST_DIAMOND::CALL_FAILED"); 

        address[] memory facetAddresses = abi.decode(data, (address[]));

        assertEq(STANDARD_FACET_COUNT + 1, facetAddresses.length);
        assertEq(_getFacetSelectors(TEST1_FACET_ADDR).length, test1FacetSelectors.length);
        assertEq( 
            keccak256(abi.encode(_getFacetSelectors(TEST1_FACET_ADDR))), 
            keccak256(abi.encode(test1FacetSelectors))
        );
        
        // Test call to a Test1Facet function
        (success, data) = diamondAddress.call(abi.encode(Test1Facet.Func2Test1.selector));
        assertTrue(success, "TEST_DIAMOND::CALL_FAILED"); 

        uint256 retVal = abi.decode(data, (uint256));
        assertEq(retVal, 2535);
        
    }

    function testRemoveAllFacet1FunctionSelectors() public {
        bool success;

        facetCuts.push(IDiamondCut.FacetCut({
            facetAddress: TEST1_FACET_ADDR,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: test1FacetSelectors
        }));

        vm.expectEmit(true, true, false, true);
        emit LibDiamond.DiamondCut(facetCuts, address(0), bytes(''));

        // Diamond Cut
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
        assertEq(_getFacetSelectors(TEST1_FACET_ADDR).length, test1FacetSelectors.length);
        
        // Test facet function selectors removal
        delete facetCuts;
        facetCuts.push(IDiamondCut.FacetCut({
            facetAddress: address(0),
            action: IDiamondCut.FacetCutAction.Remove,
            functionSelectors: test1FacetSelectors
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
        assertEq(_getFacetSelectors(TEST1_FACET_ADDR).length, 0);
    }

    function testAddMultipleFacetsAndSelectorsAndCalls() public {
        bool success;
        bytes memory data;

        facetCuts.push(IDiamondCut.FacetCut({
            facetAddress: TEST1_FACET_ADDR,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: test1FacetSelectors
        }));
        facetCuts.push(IDiamondCut.FacetCut({
            facetAddress: TEST2_FACET_ADDR,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: test2FacetSelectors
        }));

        vm.expectEmit(true, true, false, true);
        emit LibDiamond.DiamondCut(facetCuts, address(0), bytes(''));

        // Diamond Cut
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
        
        // Test Facets add and facets function selectors matching
        (success, data) = diamondAddress.call(abi.encode(IDiamondLoupe.facetAddresses.selector));
        
        assertTrue(success, "TEST_DIAMOND::CALL_FAILED"); 

        address[] memory facetAddresses = abi.decode(data, (address[]));

        assertEq(STANDARD_FACET_COUNT + 2, facetAddresses.length);
        assertEq(_getFacetSelectors(TEST1_FACET_ADDR).length, test1FacetSelectors.length);
        assertEq( 
            keccak256(abi.encode(_getFacetSelectors(TEST1_FACET_ADDR))), 
            keccak256(abi.encode(test1FacetSelectors))
        );
        assertEq(_getFacetSelectors(TEST2_FACET_ADDR).length, test2FacetSelectors.length);
        assertEq( 
            keccak256(abi.encode(_getFacetSelectors(TEST2_FACET_ADDR))), 
            keccak256(abi.encode(test2FacetSelectors))
        );
        
        (success, ) = diamondAddress.call(abi.encode(Test1Facet.Func1Test1.selector));
        assertTrue(success, "TEST_DIAMOND::CALL_FAILED");

        (success,) = diamondAddress.call(abi.encode(Test2Facet.Func3Test2.selector));
        assertTrue(success, "TEST_DIAMOND::CALL_FAILED"); 
    }

    function testReplaceSupportsInterfaceFunction() public {
        bool success;

        facetCuts.push(IDiamondCut.FacetCut({
            facetAddress: TEST1_FACET_ADDR,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: test1FacetSelectors
        }));

        // Diamond Cut
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
        assertEq(_getFacetSelectors(TEST1_FACET_ADDR).length, test1FacetSelectors.length);

        // Test supportsInterface() replace
        delete facetCuts;
        facetCuts.push(IDiamondCut.FacetCut({
            facetAddress: TEST1_FACET_ADDR,
            action: IDiamondCut.FacetCutAction.Replace,
            functionSelectors: test1FacetSupportsInterfaceSelector
        }));

        vm.expectEmit(true, true, false, true);
        emit LibDiamond.DiamondCut(facetCuts, address(0), bytes(''));

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
        assertEq(_getFacetSelectors(TEST1_FACET_ADDR).length, test1FacetSelectors.length + 1);
        assertEq(_getFacetByFunctionSelector(Test1Facet.supportsInterface.selector), TEST1_FACET_ADDR);
        assertEq(
            keccak256(abi.encode(_getFacetSelectors(TEST1_FACET_ADDR))),
            keccak256(abi.encode(test1FacetSelectorsWithSupportsInterface))
        );
    }

    function testTransferOwnership() public {
        bool success;
        bytes memory data;

        vm.expectEmit(true, true, false, false);
        emit LibDiamond.OwnershipTransferred(DIAMOND_OWNER, DEFAULT_EOA);

        vm.prank(DIAMOND_OWNER);
        (success, ) = diamondAddress.call(
            abi.encodeWithSelector(
                OwnershipFacet.transferOwnership.selector,
                DEFAULT_EOA
            )
        );

        assertTrue(success, "TEST_DIAMOND::CALL_FAILED");

        (success, data) = diamondAddress.call(
            abi.encode(OwnershipFacet.owner.selector)
        );

        assertTrue(success, "TEST_DIAMOND::CALL_FAILED");

        address retVal = abi.decode(data, (address));

        assertEq(retVal, DEFAULT_EOA);
    }
}