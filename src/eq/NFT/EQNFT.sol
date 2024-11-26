// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../base/Ownable.sol";
import "../interfaces/INFT.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract EQNFT is INFT, ERC721, Ownable {
    // Mapping of authorized mint addresses
    mapping(address => bool) public mintAddress;
    // Base URI for token metadata
    string public baseURI;
    // Token ID counter
    uint256 private _tokenIdCounter;
    // Mapping to track existing token IDs
    mapping(uint256 => bool) private _existingTokenIds;

    // Event declarations
    event Mint(address indexed to, uint256 indexed tokenId);
    event MintAddressUpdated(address indexed mintAddress, bool enabled);
    event BaseURIUpdated(string newBaseURI);

    // Constructor to initialize the contract
    constructor(
        string memory name,
        string memory symbol,
        string memory initialBaseURI
    ) ERC721(name, symbol) {
        require(bytes(name).length > 0, "Name cannot be empty.");
        require(bytes(symbol).length > 0, "Symbol cannot be empty.");
        require(bytes(initialBaseURI).length > 0, "Initial base URI cannot be empty.");
        baseURI = initialBaseURI; // Set initial base URI
    }

    // Function to set authorized mint addresses
    function setMintAddress(address _address, bool _enable)
        external
        onlyOwner
    {
        require(_address != address(0), "Invalid mint address.");
        mintAddress[_address] = _enable;
        emit MintAddressUpdated(_address, _enable); // Emit event
    }

    // Function to set the base URI
    function setBaseURI(string memory _tokenURI) external onlyOwner {
        require(bytes(_tokenURI).length > 0, "Base URI cannot be empty.");
        baseURI = _tokenURI;
        emit BaseURIUpdated(_tokenURI); // Emit event
    }

    // Function to mint a new NFT
    function mint(address _to) external returns (uint256) {
        require(
            mintAddress[msg.sender],
            "This address is not authorized to mint NFTs."
        );

        _tokenIdCounter++;

        uint256 tokenId = _tokenIdCounter;

        _safeMint(_to, tokenId); 

        // Mark the tokenId as existing
        _existingTokenIds[tokenId] = true;

        emit Mint(_to, tokenId); // Emit mint event
        return tokenId;
    }

    // Override tokenURI function to return the token's URI
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _tokenExists(tokenId),
            "ERC721: URI query for nonexistent token."
        );
        return super.tokenURI(tokenId);
    }

    // Internal function to check if a token exists
    function _tokenExists(uint256 tokenId) internal view returns (bool) {
        return _existingTokenIds[tokenId];
    }
    
    // Override _baseURI to return the base URI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}
