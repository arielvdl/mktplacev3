// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";    
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

contract GotasNFTMarketplace is Ownable, ReentrancyGuard, Pausable {

  struct Listing {
    address nftContractAddress;
    uint256[] nftIds;      
    address seller;
    uint256 price;      
    uint256 deadline;
  }

  struct TokenInfo {
    uint256 tokenId;
    string metadataLink;
  }

  uint256[] public activeListingIds;
  uint256 public royaltyPercentage;
  uint256 public platformFeePercentage;

  address public royaltyAddress;    
  address public platformFeeAddress;

  mapping(uint256 => Listing) public listings;
  mapping(uint256 => address) public listingOwners;

  uint256 public nextListingId = 1;

  event NFTListed(uint256 indexed listingId, address indexed seller, address indexed nftContract, uint256[] nftIds, uint256 price, uint256 deadline);
  event NFTSold(uint256 indexed listingId, address indexed seller, address indexed buyer, uint256 price);
  event NFTDelisted(uint256 indexed listingId);

  

// Adicione uma variável de estado para acompanhar o saldo do contrato
uint256 public contractBalance;

constructor(uint256 _royaltyPercentage, uint256 _platformFeePercentage, address _royaltyAddress, address _platformFeeAddress) {
    require(_royaltyAddress != address(0) && _platformFeeAddress != address(0), "Enderecos nao podem ser zero");
    royaltyPercentage = _royaltyPercentage;
    platformFeePercentage = _platformFeePercentage;
    royaltyAddress = _royaltyAddress;
    platformFeeAddress = _platformFeeAddress;

    // Inicialize os mapeamentos aqui
    listings[0] = Listing(address(0), new uint256[](0), address(0), 0, 0);
    listingOwners[0] = address(0);
}

// Função para permitir que o proprietário do contrato retire ether
function withdrawEther() external onlyOwner {
    // Certifique-se de que haja um saldo positivo para retirar
    require(contractBalance > 0, "O saldo do contrato e zero");

    // Armazene o saldo atual para evitar ataques de reentrada
    uint256 balanceToWithdraw = contractBalance;
    contractBalance = 0;

    // Transfira o saldo para o proprietário do contrato
    payable(owner()).transfer(balanceToWithdraw);
}


  function listNFT(address _nftContractAddress, uint256[] memory _nftIds, uint256 _price, uint256 _deadline) external whenNotPaused nonReentrant {
    // function body
  }

  function buyNFT(uint256 _listingId) external payable whenNotPaused nonReentrant {
   // function body 
  }

  function cancelListing(uint256 _listingId) external nonReentrant {
   // function body
  }

  function pause() external onlyOwner nonReentrant {
   // function body
  }

    function unpause() external onlyOwner nonReentrant {
        _unpause();
    }

    function updateFeeAddresses(address _newRoyaltyAddress, address _newPlatformFeeAddress) external onlyOwner nonReentrant {
        require(_newRoyaltyAddress != address(0) && _newPlatformFeeAddress != address(0), "Addresses cannot be zero");
        royaltyAddress = _newRoyaltyAddress;
        platformFeeAddress = _newPlatformFeeAddress;
    }

    function updateFeePercentages(uint256 _newRoyaltyPercentage, uint256 _newPlatformFeePercentage) external onlyOwner nonReentrant {
        royaltyPercentage = _newRoyaltyPercentage;
        platformFeePercentage = _newPlatformFeePercentage;
    }

    function getAllListingIds() external view returns (uint256[] memory) {
        return activeListingIds;
    }

    function getListingInfo(uint256 _listingId) external view returns (TokenInfo[] memory) {
        Listing storage listing = listings[_listingId];
        require(listing.seller != address(0), "Listing does not exist.");

        TokenInfo[] memory tokenInfoArray = new TokenInfo[](listing.nftIds.length);

        for (uint256 i = 0; i < listing.nftIds.length; i++) {
            uint256 _nftId = listing.nftIds[i];
            string memory tokenMetadataLink = "";

            try IERC721Metadata(listing.nftContractAddress).tokenURI(_nftId) returns (string memory metadataLink) {
                tokenMetadataLink = metadataLink;
            } catch {}

            tokenInfoArray[i] = TokenInfo(_nftId, tokenMetadataLink);
        }

        return tokenInfoArray;
    }
}
