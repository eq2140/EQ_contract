// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";
import "../interfaces/IUserNonce.sol";
import "../interfaces/IAllowContract.sol";

contract UserNonce is IUserNonce, Ownable {
    mapping(address => uint256) public userNonceList;
    mapping(address => uint256) public userLastBlockList;
    uint256 public lockBlock = 1;
    address public allowContractAddress;

    event LockBlockUpdated(uint256 newLockBlock);
    event UserNonceSet(address indexed user, uint256 nonce);
    event UserLastBlockUpdated(address indexed user, uint256 blockNumber);
    event AllowedContractAddressUpdated(address indexed newAddress);

    constructor(address _allowContractAddress) {
        require(_allowContractAddress != address(0), "Invalid allow contract address");
        allowContractAddress = _allowContractAddress;
    }

    event IncrementUserNonce(address indexed user, uint256 nonce, string flag);

    function setLockBlock(uint256 _num) public onlyOwner {
        lockBlock = _num;
        emit LockBlockUpdated(_num);
    }

    function setUserNonce(address _user, uint256 _nonce) public onlyOwner {
        require(_user != address(0), "Invalid address.");
        userNonceList[_user] = _nonce;
        emit UserNonceSet(_user, _nonce);
    }

    function updateUserLastBlock(address _user, uint256 _block)
        public
        onlyOwner
    {
        require(_user != address(0), "Invalid address.");
        userLastBlockList[_user] = _block;
        emit UserLastBlockUpdated(_user, _block);
    }

    // set a contract to the allowed list
    function setAllowedContractAddress(address _address) public onlyOwner {
        require(_address != address(0), "Invalid allowed contract address.");
        allowContractAddress = _address;
        emit AllowedContractAddressUpdated(_address);
    }

    function getAndIncrementUserNonce(address _user, string memory _flag)
        public
        override
        returns (uint256)
    {
        require(
            IAllowContract(allowContractAddress).isAllowed(msg.sender),
            "Caller is not an allowed contract."
        );
        require(_user != address(0), "Invalid address.");

        uint256 lastBlock = userLastBlockList[_user];
        require(
            block.number - lockBlock >= lastBlock,
            "Operation locked for this block."
        );

        uint256 nonce = userNonceList[_user];
        uint256 newNonce = nonce + 1;
        userNonceList[_user] = newNonce;
        userLastBlockList[_user] = block.number;

        emit IncrementUserNonce(_user, newNonce, _flag);
        return nonce;
    }
}
