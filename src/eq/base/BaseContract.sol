/**
 * SPDX-License-Identifier: MI231321T
 */
pragma solidity >=0.8.0 <0.9.0;

import "./Ownable.sol";
import "../interfaces/IAllowContract.sol";
import "../interfaces/IToken.sol";

abstract contract BaseContract is Ownable {
    
    address public allowContractAddress;
    
    address public signAddress;

    //
    bool public paused = false;
    
    modifier isHuman() {
        require(tx.origin == msg.sender, "sorry humans only");
        _;
    }

    modifier isAllowContract() {
        require(
            IAllowContract(allowContractAddress).has(msg.sender),
            "not allow contract"
        );
        _;
    }

    modifier isPaused() {
        require(!paused, "paused");
        _;
    }

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function setAllowContractAddress(address _address) public onlyOwner {
        allowContractAddress = _address;
    }

    function setSignAddress(address _address) public onlyOwner {
        signAddress = _address;
    }
    
    function getBalance() public view returns(uint256)
    {
        return address(this).balance;
    }

    function getTokenBalance(address _tokenAddress) public view returns(uint256)
    {
        return IToken(_tokenAddress).balanceOf(address(this));
    }

    // function ownerSweep(address _tokenAddress) public onlyOwner {
    //     uint256 amount = IToken(_tokenAddress).balanceOf(address(this));
    //     if (amount > 0) {
    //         IToken(_tokenAddress).transfer(msg.sender, amount);
    //     }
    // }

    // function ownerWithdraw() public onlyOwner {
    //     uint256 b = address(this).balance;
    //     require(b > 0, "insufficient balance.");
    //     payable(owner()).transfer(b);
    // }
}
