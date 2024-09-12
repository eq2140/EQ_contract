// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./BaseContract.sol";
import "../interfaces/IAllowContract.sol";

contract AllowContract is Ownable, IAllowContract {
    mapping(address => bool) contractList;

    bool private locked;

    modifier noReentrancy() {
        require(!locked, "No reentrancy");
        locked = true;
        _;
        locked = false;
    }

    function set(address[] memory _list, bool _bool) public onlyOwner noReentrancy {

        for (uint256 i = 0; i < _list.length; i++) {
            contractList[_list[i]] = _bool;
        }
       
    }

    function has(address _addr) public view override returns (bool) {
        require(contractList[_addr] == true,"no call permission");
        return contractList[_addr] == true;
    }
}
