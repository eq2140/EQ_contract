/**
 * SPDX-License-Identifier: MI231321T
 */
pragma solidity >=0.8.0 <0.9.0;

import "./base/BaseContract.sol";
import "./interfaces/IUserNonce.sol";
import "./interfaces/ISign.sol";

contract Sign is BaseContract, ISign {
    
    address public verifyAddress;
    address public userNonceAddress;

    constructor(
        address _verifyAddress,
        address _userNonceAddress,
        address _allowContractAddress
    ) {
        allowContractAddress = _allowContractAddress;
        verifyAddress = _verifyAddress;
        userNonceAddress = _userNonceAddress;
    }

    function setVerifyAddress(address _address) public onlyOwner {
        verifyAddress = _address;
    }

    function setUserNonceAddress(address _address) public onlyOwner {
        userNonceAddress = _address;
    }

    function getSignerAddress(
        bytes32 _messageHash,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public pure returns (address) {
        return ecrecover(_messageHash, _v, _r, _s);
    }

    function verifyMessage(
        bytes32 _messageHash,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public view returns (bool) {
        require(verifyAddress != address(0), "verify address is zero address.");
        return getSignerAddress(_messageHash, _v, _r, _s) == verifyAddress;
    }

    function getCurrentMessageHash(
        address _contractAddress,
        address _toAddress,
        string memory _funcName,
        bytes32 _messageHash,
        uint256 _nonce,
        Seed memory _seed
    ) public pure returns (bytes32) {
        require(_contractAddress != address(0), "contract address is zero address.");
        require(_toAddress != address(0), "to address is zero address.");
        return
            keccak256(
                abi.encodePacked(
                    _contractAddress,
                    _toAddress,
                    _funcName,
                    _seed.sSeed,
                    _nonce,
                    _seed.flag,
                    _messageHash
                )
            );
    }

    function verifyCurrentStandardMessage(
        address _contractAddress,
        address _toAddress,
        string memory _funcName,
        bytes32 _messageHash,
        uint256 _nonce,
        Seed memory _seed
    ) public view returns (bool) {
        require(_contractAddress != address(0), "contract address is zero address.");
        require(_toAddress != address(0), "to address is zero address.");
        bytes32 _msgHash = getCurrentMessageHash(
            _contractAddress,
            _toAddress,
            _funcName,
            _messageHash,
            _nonce,
            _seed
        );
        return verifyMessage(_msgHash, _seed.v, _seed.r, _seed.s);
    }

    function checkSign(
        address _toAddress,
        string memory _funcName,
        bytes32 _hashMessage,
        Seed memory _seed
    ) public override isAllowContract {
        require(_toAddress != address(0), "to address is zero address.");
        uint256 _nonce = IUserNonce(userNonceAddress).getAndIncrementUserNonce(
            _toAddress,
            _seed.flag
        );

        require(
            verifyCurrentStandardMessage(
                msg.sender,
                _toAddress,
                _funcName,
                _hashMessage,
                _nonce,
                _seed
            ),
            "signature is invalid."
        );
    }
}
