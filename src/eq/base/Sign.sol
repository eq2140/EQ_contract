// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";
import "../interfaces/IUserNonce.sol";
import "../interfaces/ISign.sol";
import "../interfaces/IAllowContract.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Sign is Ownable, EIP712, ISign {
    address public verifyAddress;
    address public userNonceAddress;
    address public allowContractAddress;

    string private constant SIGNING_DOMAIN = "EQ2140";
    string private constant SIGNATURE_VERSION = "1";

    event VerifyAddressUpdated(address indexed newAddress);
    event UserNonceAddressUpdated(address indexed newAddress);
    event AllowContractAddressUpdated(address indexed newAddress);

    struct Message {
        address contractAddress;
        address toAddress;
        string funcName;
        bytes32 messageHash;
        uint256 nonce;
        string flag;
    }

    bytes32 private constant MESSAGE_TYPEHASH =
        keccak256(
            "Message(address contractAddress,address toAddress,string funcName,bytes32 messageHash,uint256 nonce,string flag)"
        );

    constructor(
        address _verifyAddress,
        address _userNonceAddress,
        address _allowContractAddress
    ) EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        setVerifyAddress(_verifyAddress);
        setUserNonceAddress(_userNonceAddress);
        setAllowContractAddress(_allowContractAddress);
    }

    function setVerifyAddress(address _address) public onlyOwner {
        require(
            verifyAddress == address(0),
            "Addresses are not allowed to be changed"
        );
        _validateAddress(_address);
        verifyAddress = _address;
        emit VerifyAddressUpdated(_address);
    }

    function setUserNonceAddress(address _address) public onlyOwner {
        require(
            userNonceAddress == address(0),
            "Addresses are not allowed to be changed"
        );

        _validateAddress(_address);
        userNonceAddress = _address;
        emit UserNonceAddressUpdated(_address);
    }

    function setAllowContractAddress(address _address) public onlyOwner {
        require(
            allowContractAddress == address(0),
            "Addresses are not allowed to be changed"
        );

        _validateAddress(_address);
        allowContractAddress = _address;
        emit AllowContractAddressUpdated(_address);
    }

    function _hashMessage(Message memory message)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        MESSAGE_TYPEHASH,
                        message.contractAddress,
                        message.toAddress,
                        keccak256(bytes(message.funcName)),
                        message.messageHash,
                        message.nonce,
                        keccak256(bytes(message.flag))
                    )
                )
            );
    }

    function verifyMessage(
        Message memory message,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) internal view returns (bool) {
        address recoveredAddress = ECDSA.recover(
            _hashMessage(message),
            v,
            r,
            s
        );
        return recoveredAddress == verifyAddress;
    }

    function checkSign(
        address _toAddress,
        string memory _funcName,
        bytes32 _messageHash,
        Seed memory _seed
    ) public override {
        require(
            IAllowContract(allowContractAddress).isAllowed(msg.sender),
            "Caller is not an allowed contract."
        );
        uint256 _nonce = IUserNonce(userNonceAddress).getAndIncrementUserNonce(
            _toAddress,
            _seed.flag
        );

        Message memory message = Message({
            contractAddress: msg.sender,
            toAddress: _toAddress,
            funcName: _funcName,
            messageHash: _messageHash,
            nonce: _nonce,
            flag: _seed.flag
        });

        require(
            verifyMessage(message, _seed.r, _seed.s, _seed.v),
            "Invalid signature."
        );
    }

    function _validateAddress(address _addr) private pure {
        require(_addr != address(0), "Invalid address.");
    }
}
