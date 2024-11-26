// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../base/Ownable.sol";
import "../interfaces/IPancakeRouter.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract EQ is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 21_000_000 * 10**18;
    uint256 public totalMintCount;
    uint256 public currentMintCount;
    uint256 public mintQuantity = 5_000 * 10**18;
    uint256 public halveCount;
    uint256 public lastMintBlock;

    address public mintNodeAddress;
    address public mintPoolAddress;
    address public taxAddress;

    uint256 public dexTaxFee = 300; // 3% sell EQ token fee
    uint256 public constant MAX_DEX_TAX_FEE = 500; // 5% max sell EQ token fee

    address public immutable pairAddress;
    address public routerAddress;

    event MintEvent(
        uint256 mintNodeAmount,
        address mintNodeAddress,
        uint256 mintPoolAmount,
        address mintPoolAddress
    );
    event NodeMintAddressUpdated(address newNodeAddress);
    event PoolMintAddressUpdated(address newPoolAddress);
    event TaxAddressUpdated(address newTaxAddress);
    event TaxUpdated(uint256 newTaxFee);
    event TransferTaxPaid(address from, address to, uint256 taxFee);
    event PairAddressCreated(address pairAddress);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        address _usdtAddress,
        address _routerAddress
    ) ERC20(_name, _symbol) {
        uint256 supply = _initialSupply * 10**decimals();
        require(MAX_SUPPLY >= supply, "The supply limit has been reached");
        _mint(_msgSender(), supply);

        taxAddress = _msgSender();
        routerAddress = _routerAddress;
        IPancakeRouter router = IPancakeRouter(routerAddress);
        pairAddress = IPancakeRouter(router.factory()).createPair(
            address(this),
            _usdtAddress
        );
        require(pairAddress != address(0), "Pair creation failed");
        emit PairAddressCreated(pairAddress);
    }

    function mint() public onlyOwner {
        require(mintNodeAddress != address(0), "Node address not set");
        require(mintPoolAddress != address(0), "Pool address not set");
        require(totalSupply() < MAX_SUPPLY, "Supply limit reached");
        require(
            block.number >= lastMintBlock + 6000,
            "Minting blocked for 6000 blocks"
        );

        if (halveCount < 3 && currentMintCount >= 1460) {
            currentMintCount = 0;
            mintQuantity /= 2;
            halveCount++;
        }

        uint256 remainingQuantity = MAX_SUPPLY - totalSupply();
        uint256 actualMintQuantity = mintQuantity > remainingQuantity
            ? remainingQuantity
            : mintQuantity;

        currentMintCount++;
        totalMintCount++;

        uint256 mintNodeAmount = actualMintQuantity / 20; // 5%
        uint256 mintPoolAmount = actualMintQuantity - mintNodeAmount; // 95%

        _mint(mintNodeAddress, mintNodeAmount);
        _mint(mintPoolAddress, mintPoolAmount);

        lastMintBlock = block.number;

        emit MintEvent(
            mintNodeAmount,
            mintNodeAddress,
            mintPoolAmount,
            mintPoolAddress
        );
    }

    function setNodeMintAddress(address _address) public onlyOwner {
        require(
            mintNodeAddress == address(0),
            "Addresses are not allowed to be changed"
        );

        require(_address != address(0), "Node address cannot be zero.");
        mintNodeAddress = _address;
        emit NodeMintAddressUpdated(_address);
    }

    function setPoolMintAddress(address _address) public onlyOwner {
        require(
            mintPoolAddress == address(0),
            "Addresses are not allowed to be changed"
        );

        require(_address != address(0), "Pool address cannot be zero.");
        mintPoolAddress = _address;
        emit PoolMintAddressUpdated(_address);
    }

    function setTaxAddress(address _address) public onlyOwner {
        require(_address != address(0), "Tax address cannot be zero.");
        taxAddress = _address;
        emit TaxAddressUpdated(_address);
    }

    function setTax(uint256 _taxFee) public onlyOwner {
        require(_taxFee <= MAX_DEX_TAX_FEE, "Exceeds max tax fee");
        dexTaxFee = _taxFee;
        emit TaxUpdated(_taxFee);
    }

    function _beforeTransfer(
        address from,
        address to,
        uint256 amount
    ) private returns (uint256) {
        require(to != address(this), "Cannot send to contract address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 taxFee = 0;
        if (to == pairAddress) {
            taxFee = (amount * dexTaxFee) / 10_000;
            require(amount > taxFee, "Amount less than tax fee");
            _transfer(from, taxAddress, taxFee);
            emit TransferTaxPaid(from, taxAddress, taxFee);
        }

        return amount - taxFee;
    }

    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        address from = _msgSender();

        uint256 finalAmount = _beforeTransfer(from, to, amount);

        _transfer(from, to, finalAmount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        address spender = _msgSender();
        uint256 currentAllowance = allowance(from, spender);
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );

        _approve(from, spender, currentAllowance - amount);

        uint256 finalAmount = _beforeTransfer(from, to, amount);

        _transfer(from, to, finalAmount);

        return true;
    }
}
