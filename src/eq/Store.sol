// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./base/Ownable.sol";
import "./interfaces/IPancakeRouter.sol";
import "./interfaces/INFT.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Store is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant RATIO_DENOMINATOR = 10000;

    bool private isBuyGasAllocAddressSet;

    address public tokenAddress;
    address public usdtTokenAddress;
    address public nftTokenAddress;
    address public adminAddress;
    address public nodeAddress;

    uint256 public buyNFTUsdtAllocAdminRatio;
    uint256 public buyNFTUsdtAmount;

    mapping(uint256 => uint256) public buyGasAllocRatioList;
    mapping(uint256 => address) public buyGasAllocAddressList;

    IPancakeRouter public immutable pancakeRouter;

    event BuyGasEvent(
        address indexed from,
        uint256 usdtAmount,
        uint256 tokenAmount,
        uint256[] allocAmountList,
        address[] allocAddressList
    );
    event BuyNFTEvent(
        address indexed from,
        uint256 itemId,
        uint256 usdtAmount,
        uint256 toAdminUsdt,
        uint256 buyTokenUsdt,
        uint256 tokenAmount
    );

    error InvalidAddress();
    error AlreadySet();

    constructor(
        address _routerAddress,
        address _tokenAddress,
        address _usdtTokenAddress,
        address _nftTokenAddress,
        address _nodeAddress
    ) {
        if (_routerAddress == address(0)) revert InvalidAddress();
        if (_tokenAddress == address(0)) revert InvalidAddress();
        if (_usdtTokenAddress == address(0)) revert InvalidAddress();
        if (_nftTokenAddress == address(0)) revert InvalidAddress();
        if (_nodeAddress == address(0)) revert InvalidAddress();

        pancakeRouter = IPancakeRouter(_routerAddress);
        tokenAddress = _tokenAddress;
        usdtTokenAddress = _usdtTokenAddress;
        nftTokenAddress = _nftTokenAddress;
        nodeAddress = _nodeAddress;
    }

    function setAdminAddress(address _address) external onlyOwner {
        if (_address == address(0)) revert InvalidAddress();
        adminAddress = _address;
    }

    function setBuyNFTUsdtAllocAdminRatio(uint256 _ratio) external onlyOwner {
        buyNFTUsdtAllocAdminRatio = _ratio;
    }

    function setBuyNFTUsdtAmount(uint256 _amount) external onlyOwner {
        buyNFTUsdtAmount = _amount;
    }

    function setBuyGasAllocRatio(
        uint256 _ratio1,
        uint256 _ratio2,
        uint256 _ratio3,
        uint256 _ratio4
    ) external onlyOwner {
        require(
            _ratio1 + _ratio2 + _ratio3 + _ratio4 == RATIO_DENOMINATOR,
            "The proportions must sum to 10000"
        );
        buyGasAllocRatioList[1] = _ratio1;
        buyGasAllocRatioList[2] = _ratio2;
        buyGasAllocRatioList[3] = _ratio3;
        buyGasAllocRatioList[4] = _ratio4;
    }

    function setBuyGasAllocAddress(
        address _address2,
        address _address3,
        address _address4
    ) external onlyOwner {
        if (isBuyGasAllocAddressSet) revert AlreadySet();

        if (
            _address2 == address(0) ||
            _address3 == address(0) ||
            _address4 == address(0)
        ) revert InvalidAddress();
        buyGasAllocAddressList[2] = _address2;
        buyGasAllocAddressList[3] = _address3;
        buyGasAllocAddressList[4] = _address4;

        isBuyGasAllocAddressSet = true;
    }

    function setBuyGasAllocAddress3(address _address3) external onlyOwner {
        if (_address3 == address(0)) revert InvalidAddress();

        buyGasAllocAddressList[3] = _address3;
    }

    function buyGas(uint256 usdtAmount, uint256 amountOutMin)
        external
        nonReentrant
    {
        require(usdtAmount > 0, "USDT amount must be greater than zero");
        IERC20(usdtTokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            usdtAmount
        );

        IERC20(usdtTokenAddress).safeIncreaseAllowance(
            address(pancakeRouter),
            usdtAmount
        );

        address[] memory path = new address[](2);
        path[0] = usdtTokenAddress;
        path[1] = tokenAddress;

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

        uint256 totalAllocated = 0;
        uint256 allocAmount = 0;

        for (uint256 i = 0; i < 3; i++) {
            allocAmount =
                (tokenAmount * buyGasAllocRatioList[i + 1]) /
                RATIO_DENOMINATOR;
            allocTokenAmountList[i] = allocAmount;
            totalAllocated += allocAmount;
            IERC20(tokenAddress).safeTransfer(
                allocTokenAddressList[i],
                allocAmount
            );
        }

        uint256 remainingAmount = tokenAmount - totalAllocated;
        allocTokenAmountList[3] = remainingAmount;
        IERC20(tokenAddress).safeTransfer(
            allocTokenAddressList[3],
            remainingAmount
        );

        emit BuyGasEvent(
            msg.sender,
            usdtAmount,
            tokenAmount,
            allocTokenAmountList,
            allocTokenAddressList
        );
    }

    function buyNFT(uint256 amountOutMin) external nonReentrant {
        require(
            buyNFTUsdtAmount > 0,
            "NFT purchase amount must be greater than zero"
        );

        IERC20(usdtTokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            buyNFTUsdtAmount
        );

        uint256 toAdminAmount = (buyNFTUsdtAmount * buyNFTUsdtAllocAdminRatio) /
            RATIO_DENOMINATOR;
        IERC20(usdtTokenAddress).safeTransfer(adminAddress, toAdminAmount);

        uint256 toBuyEQ = buyNFTUsdtAmount - toAdminAmount;

        IERC20(usdtTokenAddress).safeIncreaseAllowance(
            address(pancakeRouter),
            toBuyEQ
        );

        address[] memory path = new address[](2);
        path[0] = usdtTokenAddress;
        path[1] = tokenAddress;

        uint256[] memory amounts = pancakeRouter.swapExactTokensForTokens(
            toBuyEQ,
            amountOutMin,
            path,
            nodeAddress,
            block.timestamp
        );

        uint256 tokenAmount = amounts[1];
        uint256 newItemId = INFT(nftTokenAddress).mint(msg.sender);

        emit BuyNFTEvent(
            msg.sender,
            newItemId,
            buyNFTUsdtAmount,
            toAdminAmount,
            toBuyEQ,
            tokenAmount
        );
    }
}
