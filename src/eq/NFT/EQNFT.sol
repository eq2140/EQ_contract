// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract EQNFT is ERC721, Ownable {


  bool private locked;

    modifier noReentrancy() {
        require(!locked, "No reentrancy");
        locked = true;
        _;
        locked = false;
    }

    mapping(address => bool) public mintAddress;

    function setMint(address _address, bool _enable) external onlyOwner {
        mintAddress[_address] = _enable;
    }

    
    uint256 public tokenId;

    
    constructor() ERC721("EQ NFT", "EQNFT") Ownable(msg.sender) {
        
    }

    string public baseURI;

    function setBaseURI(string memory _tokenURI) external onlyOwner {
        baseURI = _tokenURI;
    }


    function mint(address _to) noReentrancy public returns (uint256 _itemId)  {
        require(mintAddress[msg.sender]==true,"no mint permission");
       _mint(_to, ++tokenId);
        return tokenId;
    }

    
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_ownerOf(_tokenId) != address(0), "ERC721: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }
}
