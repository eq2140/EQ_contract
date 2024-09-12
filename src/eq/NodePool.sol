// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./base/BaseContract.sol";
import "./interfaces/IToken.sol";
import "./interfaces/ISign.sol";


contract NodePool is BaseContract {
    
    address public tokenAddress;

    
    mapping(uint256 => bool) public awardIdList;

    
    event receiveNodeAwardEvent(address _to, uint256 _awardId, uint256 _amount);

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

    
    function receiveNodeAward(
        uint256 _awardId,
        uint256 _amount,
        ISign.Seed memory _seed
    ) public isHuman isPaused {

        require(_awardId > 1000000000000000001 && _awardId<99999999999999999999 , "id parameter error");

        bytes32 _hashMessage = keccak256(abi.encodePacked(_awardId, _amount));
        ISign(signAddress).checkSign(
            msg.sender,
            "receiveNodeAward",
            _hashMessage,
            _seed
        );

        
        require(!awardIdList[_awardId], "repeat receive");

         
        awardIdList[_awardId] = true;

        
        IToken(tokenAddress).transfer(msg.sender, _amount);
       
        
        emit receiveNodeAwardEvent(msg.sender, _awardId, _amount);
    }
}
