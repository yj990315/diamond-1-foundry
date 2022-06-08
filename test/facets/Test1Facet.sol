// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test1Facet {
    event TestEvent(address something);
    function Func1Test1() external {}
    function Func2Test1() external pure returns(uint256) { return 2535; }
    function Func3Test1() external {}
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}
}
