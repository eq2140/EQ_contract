// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


interface INFT {

    function mint(address _to) external returns (uint256 _itemId);
}