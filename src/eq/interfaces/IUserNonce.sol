/**
 * SPDX-License-Identifier: MI231321T
*/
pragma solidity >=0.8.0 <0.9.0;

interface IUserNonce {
    function getAndIncrementUserNonce(address _address, string memory _flag) external returns (uint256);
}
