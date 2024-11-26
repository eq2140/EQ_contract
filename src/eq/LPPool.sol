// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./base/Ownable.sol";
import "./interfaces/ISign.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract LPPool is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public tokenAddress;
    address public signAddress;
    address public lpTokenAddress;

    uint256 public constant MIN_AWARD_ID = 1e18 + 1; // 1000000000000000001
    uint256 public constant MAX_AWARD_ID = 1e21 - 1; // 99999999999999999999

    mapping(uint256 => bool) public awardIdList;
    mapping(uint256 => bool) public unDepositLPIdList;
    mapping(address => uint256) public lpDepositList;

    uint256 public lpTotal;

    event ReceiveAwardEvent(address indexed from, uint256 indexed awardId, uint256 amount);
    event DepositLPEvent(address indexed from, uint256 amount);
    event UnDepositLPEvent(uint256 indexed unDepositLPId, address indexed to, uint256 amount);


    constructor(address _signAddress, address _tokenAddress, address _lpTokenAddress) {
        require(_signAddress != address(0), "Invalid sign address");
        require(_tokenAddress != address(0), "Invalid token address");
        require(_lpTokenAddress != address(0), "Invalid LP token address");

        signAddress = _signAddress;
        tokenAddress = _tokenAddress;
        lpTokenAddress = _lpTokenAddress;
    }

  

    function receiveAward(uint256 _awardId, uint256 _amount, ISign.Seed memory _seed) external {
        require(_awardId > MIN_AWARD_ID && _awardId < MAX_AWARD_ID, "Invalid award ID");
        require(_amount > 0, "Amount must be greater than 0");

        bytes32 _hashMessage = keccak256(abi.encode(_awardId, _amount));
        ISign(signAddress).checkSign(msg.sender, "receiveAward", _hashMessage, _seed);

        require(!awardIdList[_awardId], "Award ID already received");
        awardIdList[_awardId] = true;

        IERC20(tokenAddress).safeTransfer(msg.sender, _amount);
        emit ReceiveAwardEvent(msg.sender, _awardId, _amount);
    }

    function depositLP(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");

        uint256 balanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));

        IERC20(lpTokenAddress).safeTransferFrom(msg.sender, address(this), _amount);

        uint256 balanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));

        uint256 actualReceived = balanceAfter - balanceBefore;
        require(actualReceived > 0, "No tokens received");

        lpDepositList[msg.sender] += actualReceived;
        lpTotal += actualReceived;

        emit DepositLPEvent(msg.sender, actualReceived);
    }

    function unDepositLP(uint256 _unDepositLPId, uint256 _amount, ISign.Seed memory _seed) external nonReentrant {
        require(_unDepositLPId > MIN_AWARD_ID && _unDepositLPId < MAX_AWARD_ID, "Invalid unDeposit ID");
        require(_amount > 0, "Amount must be greater than 0");
        require(lpDepositList[msg.sender] >= _amount, "Insufficient funds");

        bytes32 _hashMessage = keccak256(abi.encode(_unDepositLPId, _amount));
        ISign(signAddress).checkSign(msg.sender, "unDepositLP", _hashMessage, _seed);

        require(!unDepositLPIdList[_unDepositLPId], "UnDeposit ID already used");
        unDepositLPIdList[_unDepositLPId] = true;

        // Update state before interacting with external contracts
        lpDepositList[msg.sender] -= _amount;
        lpTotal -= _amount;

        // Interact with external contract
        IERC20(lpTokenAddress).safeTransfer(msg.sender, _amount);

        emit UnDepositLPEvent(_unDepositLPId, msg.sender, _amount);
    }
}
