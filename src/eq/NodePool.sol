// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./base/Ownable.sol";
import "./interfaces/ISign.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract NodePool is Ownable {
    using SafeERC20 for IERC20;

    uint256 private constant MIN_AWARD_ID = 1e18 + 1; // 1000000000000000001
    uint256 private constant MAX_AWARD_ID = 1e21 - 1; // 99999999999999999999
    address public tokenAddress;
    address public signAddress;
    mapping(uint256 => bool) public awardedIds;

    event NodeAwardReceived(address indexed recipient, uint256 indexed awardId, uint256 amount);


    constructor(address _signAddress, address _tokenAddress) {
        require(_signAddress != address(0), "Invalid sign address");
        require(_tokenAddress != address(0), "Invalid token address");

        signAddress = _signAddress;
        tokenAddress = _tokenAddress;
    }

 

    function receiveNodeAward(
        uint256 _awardId,
        uint256 _amount,
        ISign.Seed memory _seed
    ) external {
        require(_awardId > MIN_AWARD_ID && _awardId < MAX_AWARD_ID, "ID parameter error");
        require(_amount > 0, "Amount must be greater than zero");
        require(!awardedIds[_awardId], "Award has already been claimed");

        bytes32 hashMessage = keccak256(abi.encode(_awardId, _amount));
        ISign(signAddress).checkSign(msg.sender, "receiveNodeAward", hashMessage, _seed);

        awardedIds[_awardId] = true;

        IERC20(tokenAddress).safeTransfer(msg.sender, _amount);

        emit NodeAwardReceived(msg.sender, _awardId, _amount);
    }
}
