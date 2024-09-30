// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./base/BaseContract.sol";
import "./interfaces/INFT.sol";
import "./interfaces/IToken.sol";
import "./interfaces/ISign.sol";

import "./interfaces/IPancakeRouter02.sol";
import "./interfaces/IPancakeFactory.sol";

contract Store is BaseContract {
    constructor(
        address _signAddress,
        address _allowContractAddress,
        address _routerAddress
    ) {
        signAddress = _signAddress;
        allowContractAddress = _allowContractAddress;
        pancakeRouter = IPancakeRouter02(_routerAddress);
    }

    
    IPancakeRouter02 public immutable pancakeRouter;

    
    address public tokenAddress;

    
    function setTokenAddress(address _address) public onlyOwner {
        tokenAddress = _address;
    }

    
    address public usdtTokenAddress;

    
    function setUsdtTokenAddress(address _address) public onlyOwner {
        usdtTokenAddress = _address;
    }

    
    address public nftTokenAddress;

    
    function setNFTTokenAddress(address _address) public onlyOwner {
        nftTokenAddress = _address;
    }

    
    address public adminAddress;

    
    function setAdminAddress(address _address) public onlyOwner {
        adminAddress = _address;
    }

    
    address public adminTransferAddress;

    
    function setAdminTransferAddress(address _address) public onlyOwner {
        adminTransferAddress = _address;
    }

  

    //-------------------------------gas-----------------------------------------------------------

    //
    function setBuyGasAllocRatio(
        uint256 _ratio1,
        uint256 _ratio2,
        uint256 _ratio3,
        uint256 _ratio4
    ) public onlyOwner {
        require(
            _ratio1 + _ratio2 + _ratio3 + _ratio4 == 10000,
            "the proportion is wrong"
        );

        buyGasAllocRatioList[1] = _ratio1;
        buyGasAllocRatioList[2] = _ratio2;
        buyGasAllocRatioList[3] = _ratio3;
        buyGasAllocRatioList[4] = _ratio4;
    }

    //
    function setBuyGasAllocAddress(
        address _address2,
        address _address3,
        address _address4
    ) public onlyOwner {
        buyGasAllocAddressList[2] = _address2;
        buyGasAllocAddressList[3] = _address3;
        buyGasAllocAddressList[4] = _address4;
    }

    //
    mapping(uint256 => uint256) public buyGasAllocRatioList;

    //
    mapping(uint256 => address) public buyGasAllocAddressList;

    //
    event buyGasEvent(
        address _from, 
        uint256 _usdtTokenAmount, 
        uint256 _tokenAmount, 
        uint256[] _allocAmountList, 
        address[] _allocAddressList 
    );

    //
    function buyGas(uint256 usdtAmount, uint256 amountOutMin) public isHuman isPaused{
        IToken(usdtTokenAddress).approve(address(pancakeRouter), usdtAmount);


        require(usdtAmount > 0, "The amount must be greater than 0");

        address[] memory path = new address[](2);
        path[0] = usdtTokenAddress;
        path[1] = tokenAddress;

        IToken(usdtTokenAddress).transferFrom( msg.sender,address(this),usdtAmount);

        uint256[] memory amounts = pancakeRouter.swapExactTokensForTokens(
            usdtAmount,
            amountOutMin,
            path,
            address(this),
            block.timestamp
        );

        uint256 tokenAmount = amounts[1];

        address[] memory allocTokenAddressList = new address[](4);
        allocTokenAddressList[0] = msg.sender; 
        allocTokenAddressList[1] = buyGasAllocAddressList[2]; 
        allocTokenAddressList[2] = buyGasAllocAddressList[3]; 
        allocTokenAddressList[3] = buyGasAllocAddressList[4]; 

        uint256[] memory allocTokenAmountList = new uint256[](4);

        allocTokenAmountList[0] = (tokenAmount * buyGasAllocRatioList[1]) / 10000;

        allocTokenAmountList[1] = (tokenAmount * buyGasAllocRatioList[2]) / 10000;

        allocTokenAmountList[2] = (tokenAmount * buyGasAllocRatioList[3]) / 10000;

        allocTokenAmountList[3] = (tokenAmount * buyGasAllocRatioList[4]) / 10000;

        require(allocTokenAmountList[0] + allocTokenAmountList[1] + allocTokenAmountList[2] + allocTokenAmountList[3] <= tokenAmount, "alloc faild.");

        if (allocTokenAmountList[0] > 0) {
            IToken(tokenAddress).transfer(allocTokenAddressList[0],allocTokenAmountList[0]);
        }

        if (allocTokenAmountList[1] > 0) {
            IToken(tokenAddress).transfer( allocTokenAddressList[1], allocTokenAmountList[1]);
        }

        if (allocTokenAmountList[2] > 0) {
            IToken(tokenAddress).transfer( allocTokenAddressList[2], allocTokenAmountList[2]);
        }

        if (allocTokenAmountList[3] > 0) {
            IToken(tokenAddress).transfer(allocTokenAddressList[3],allocTokenAmountList[3] );
        }

        emit buyGasEvent(msg.sender, usdtAmount,tokenAmount,allocTokenAmountList,allocTokenAddressList);
    }

    //---------------------------------------------NFT-----------------------------------------------------------

    
    uint256 public buyNFTUsdtAllocAdminRatio;

    
    function setBuyNFTUsdtAllocAdminRatio(uint256 _ratio) public onlyOwner {
        buyNFTUsdtAllocAdminRatio = _ratio;
    }

    
    uint256 public buyNFTUsdtAmount;

    
    function setBuyNFTUsdtAmount(uint256 _amount) public onlyOwner {
        buyNFTUsdtAmount = _amount;
    }

   
    event buyNFTEvent(
        address _from, 
        uint256 _itemId, 
        uint256 _usdtAmount, 
        uint256 _toAdminUsdt, 
        uint256 _buyTokenUsdt, 
        uint256 _tokenAmount 
    );

    
    function buyNFT() public isHuman isPaused{
        IToken(usdtTokenAddress).transferFrom(
            msg.sender,
            address(this),
            buyNFTUsdtAmount
        );

        uint256 toAdminAmount = (buyNFTUsdtAmount * buyNFTUsdtAllocAdminRatio) /  10000;

        IToken(usdtTokenAddress).transfer(adminAddress, toAdminAmount);

        uint256 toBuyEQ = buyNFTUsdtAmount - toAdminAmount;

        IToken(usdtTokenAddress).approve(address(pancakeRouter), toBuyEQ);

        address[] memory path = new address[](2);
        path[0] = usdtTokenAddress;
        path[1] = tokenAddress;

        
        uint256[] memory amounts = pancakeRouter.swapExactTokensForTokens(
            toBuyEQ,
            0,
            path,
            adminTransferAddress,
            block.timestamp
        );

        uint256 tokenAmount = amounts[1]; 

        uint256 newItemId = INFT(nftTokenAddress).mint(msg.sender);

        emit buyNFTEvent(
            msg.sender,
            newItemId,
            buyNFTUsdtAmount,
            toAdminAmount,
            toBuyEQ,
            tokenAmount
        );
    }

    
}
