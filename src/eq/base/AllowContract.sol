// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";
import "../interfaces/IAllowContract.sol";

contract AllowContract is Ownable, IAllowContract {
    mapping(address => bool) private _allowedAddresses;

    event AddressListUpdated(address indexed addr, bool isAllowed);

    function set(address[] calldata addresses, bool allowedStatus) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            require(addr != address(0), "Invalid address: zero address");
            _allowedAddresses[addr] = allowedStatus;
            emit AddressListUpdated(addr, allowedStatus);
        }
    }

    function isAllowed(address addr) external view returns (bool) {
        return _allowedAddresses[addr];
    }

    function requireAllowed(address addr) public view {
        require(_allowedAddresses[addr], "No call permission");
    }
}
