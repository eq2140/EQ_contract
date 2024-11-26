// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IUserNonce {
    function getAndIncrementUserNonce(address _address, string memory _flag) external returns (uint256);
}
