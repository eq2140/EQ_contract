// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./base/BaseContract.sol";
import "./interfaces/IToken.sol";
import "./interfaces/ISign.sol";

contract LPPool is BaseContract {
    
    address public tokenAddress;

    
    address public lpTokenAddress;

    
    mapping(uint256 => bool) public awardIdList;

    
    mapping(uint256 => bool) public unDepositLPIdList;

    
    mapping(address => uint256) public lpDepositList;

    
    uint256 public lpTotal;


    event receiveAwardEvent(address _from, uint256 _awardId, uint256 _amount);

    event depositLPEvent(address _from, uint256 _amount);

    event unDepositLPEvent(
        uint256 _unDepositLPId,
        address _to,
        uint256 _amount
    );

    constructor(
        address _tokenAddress,
        address _signAddress,
        address _allowContractAddress
    ) {
        tokenAddress = _tokenAddress;
        signAddress = _signAddress;
        allowContractAddress = _allowContractAddress;
    }

    
    function setTokenAddress(address _address) public onlyOwner {
        tokenAddress = _address;
    }

    
    function setLPTokenAddress(address _address) public onlyOwner {
        lpTokenAddress = _address;
    }

    
    function receiveAward(
        uint256 _awardId,
        uint256 _amount,
        ISign.Seed memory _seed
    ) public isHuman isPaused {

        require(_awardId > 1000000000000000001 && _awardId<99999999999999999999 , "id parameter error");

        require(_amount > 0, "The amount must be greater than 0");

        bytes32 _hashMessage = keccak256(abi.encodePacked(_awardId, _amount));
        ISign(signAddress).checkSign(
            msg.sender,
            "receiveAward",
            _hashMessage,
            _seed
        );

        
        require(!awardIdList[_awardId], "repeat receive");

        
        awardIdList[_awardId] = true;

        
        IToken(tokenAddress).transfer(msg.sender, _amount);

        
        emit receiveAwardEvent(msg.sender, _awardId, _amount);
    }

    
    function depositLP(uint256 _amount) public isHuman isPaused {

        require(_amount > 0, "The amount must be greater than 0");

        require(
            IToken(lpTokenAddress).allowance(msg.sender, address(this)) >=
                _amount,
            "allowance insufficient"
        );

        IToken(lpTokenAddress).transferFrom(msg.sender, address(this), _amount);

        lpDepositList[msg.sender] += _amount;
        lpTotal += _amount;
        emit depositLPEvent(msg.sender, _amount);
    }

    
    function unDepositLP(
        uint256 _unDepositLPId,
        uint256 _amount,
        ISign.Seed memory _seed
    ) public isHuman isPaused {

        require(_unDepositLPId > 1000000000000000001 && _unDepositLPId<99999999999999999999 , "id parameter error");

        require(_amount > 0, "The amount must be greater than 0");

        bytes32 _hashMessage = keccak256(
            abi.encodePacked(_unDepositLPId, _amount)
        );
        ISign(signAddress).checkSign(
            msg.sender,
            "unDepositLP",
            _hashMessage,
            _seed
        );

        
        require(!unDepositLPIdList[_unDepositLPId], "repeat receive");

        require(lpDepositList[msg.sender] >= _amount, "not sufficient funds");

        unDepositLPIdList[_unDepositLPId] = true;

        IToken(lpTokenAddress).transfer(msg.sender, _amount);

        lpDepositList[msg.sender] -= _amount;

        lpTotal -= _amount;

        emit unDepositLPEvent(_unDepositLPId, msg.sender, _amount);
    }
}
