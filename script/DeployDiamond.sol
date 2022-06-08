// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "diamond-src/Diamond.sol";
import "diamond-facets/DiamondCutFacet.sol";
import "diamond-facets/DiamondLoupeFacet.sol";
import "diamond-facets/OwnershipFacet.sol";
import "diamond-init/DiamondInit.sol";
import "diamond-ifaces/IDiamondCut.sol";

contract DeployDiamond is Script {
    address private constant DIAMOND_OWNER = address(0x2535);
    address[] deployedContracts;
    bytes4[] private loupeFacetSelectors = [
        DiamondLoupeFacet.facets.selector, 
        DiamondLoupeFacet.facetFunctionSelectors.selector,
        DiamondLoupeFacet.facetAddresses.selector,
        DiamondLoupeFacet.facetAddress.selector,
        DiamondLoupeFacet.supportsInterface.selector
    ];
    bytes4[] private ownershipFacetSelectors = [
        OwnershipFacet.transferOwnership.selector, 
        OwnershipFacet.owner.selector
    ];

    DiamondCutFacet diamondCutFacet;
    Diamond diamond;
    DiamondInit diamondInit;
    DiamondLoupeFacet diamondLoupeFacet;
    OwnershipFacet ownershipFacet;
    IDiamondCut.FacetCut[] facetCuts;


    function run() external returns(address[] memory) {
        vm.startBroadcast(DIAMOND_OWNER);

        /// Deploy Diamond, Diamond Init and standard facets.
        diamondCutFacet = new DiamondCutFacet();
        diamond = new Diamond(DIAMOND_OWNER, address(diamondCutFacet));
        diamondInit = new DiamondInit();
        diamondLoupeFacet = new DiamondLoupeFacet();
        ownershipFacet = new OwnershipFacet();

        deployedContracts.push(address(diamondCutFacet));
        deployedContracts.push(address(diamond));
        deployedContracts.push(address(diamondInit));
        deployedContracts.push(address(diamondLoupeFacet));
        deployedContracts.push(address(ownershipFacet));
        
        /// Cut Facets.
        facetCuts.push(IDiamondCut.FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: loupeFacetSelectors
        }));

        facetCuts.push(IDiamondCut.FacetCut({
            facetAddress: address(ownershipFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: ownershipFacetSelectors
        }));
     
        /// Upgrade Diamond with facet cuts then call to DiamondInit.init().
        /// It is possible to pass parameters to the init() function call in order to initialize
        /// the Diamond Storage with some script data by encoding them along the init() function selector.
        (bool success, ) = address(diamond).call(
            abi.encodeWithSelector(
                IDiamondCut.diamondCut.selector, 
                facetCuts,
                address(diamondInit), 
                abi.encode(DiamondInit.init.selector)
            )
        );
        
        /// Revert if upgrade fails. 
        /// Forge will display revert messages from the Diamond if any.
        require(success, "DEPLOY::DIAMOND_UPGRADE_ERROR");

        vm.stopBroadcast();

        /// 0 => DiamonCut Facet Addr
        /// 1 => Diamond Contract Addr
        /// 2 => DiamondInit Contract Addr
        /// 3 => DiamondLoupe Facet Addr
        /// 4 => Ownership Facet Addr 
        return deployedContracts;
    }
}
