/**
 * SPDX-License-Identifier: MI231321T
 */
pragma solidity >=0.8.0 <0.9.0;

import "./base/BaseContract.sol";
import "./interfaces/IUserNonce.sol";

contract UserNonce is BaseContract, IUserNonce {
    mapping(address => uint256) public userNonceList;

    mapping(address => uint256) public userLastBlockList;

    uint256 public lockBlock = 1;

    constructor(address _allowContractAddress) {
        allowContractAddress = _allowContractAddress;
    }

    function setLockBlock(uint256 _num) public onlyOwner {
        lockBlock = _num;
    }

    function setUserNonce(address _address, uint256 _nonce) public onlyOwner {
        userNonceList[_address] = _nonce;
    }

    function setUserLastBlock(address _address, uint256 _block)
        public
        onlyOwner
    {
        userLastBlockList[_address] = _block;
    }

    event IncrementUserNonce(address _address, uint256 _nonce, string _flag);

    
    function getAndIncrementUserNonce(address _address, string memory _flag)
        public
        override
        isAllowContract
        returns (uint256)
    {
        require(_address != address(0), "address is zero address.");
        uint256 _lastBlock = userLastBlockList[_address];
        if (_lastBlock > 0) {
            require(_lastBlock <= block.number, "block error.");
            require(block.number - lockBlock >= _lastBlock, "block lock.");
        }
        uint256 _nonce = userNonceList[_address];
        userNonceList[_address] = _nonce + 1;
        emit IncrementUserNonce(_address, _nonce + 1, _flag);
        return _nonce;
    }
}
