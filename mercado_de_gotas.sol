// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol"; // Importar a interface ERC721Metadata

contract GotasNFTMarketplace is Ownable, ReentrancyGuard, Pausable {
    struct Listing {
        address nftContractAddress;
        uint256 nftId;
        address seller;
        uint256 price;
        uint256 deadline;
    }

    uint256[] public activeListingIds;
    uint256 public royaltyPercentage;
    uint256 public platformFeePercentage;

    address public royaltyAddress;
    address public platformFeeAddress;

    mapping(uint256 => Listing) public listings;
    mapping(uint256 => address) public listingOwners;

    uint256 public nextListingId = 1;

    event NFTListed(uint256 indexed listingId, address indexed seller, address indexed nftContract, uint256 nftId, uint256 price, uint256 deadline);
    event NFTSold(uint256 indexed listingId, address indexed seller, address indexed buyer, uint256 price);
    event NFTDelisted(uint256 indexed listingId);

    constructor(uint256 _royaltyPercentage, uint256 _platformFeePercentage, address _royaltyAddress, address _platformFeeAddress) {
        require(_royaltyAddress != address(0) && _platformFeeAddress != address(0), "Addresses cannot be zero");
        royaltyPercentage = _royaltyPercentage;
        platformFeePercentage = _platformFeePercentage;
        royaltyAddress = _royaltyAddress;
        platformFeeAddress = _platformFeeAddress;
    }

    function listNFT(address _nftContractAddress, uint256 _nftId, uint256 _price, uint256 _deadline) external whenNotPaused nonReentrant {
        require(_price > 0, "Price must be greater than zero.");
        require(_deadline > 0, "Deadline must be greater than zero.");

        IERC721 nftContract = IERC721(_nftContractAddress);
        require(nftContract.ownerOf(_nftId) == msg.sender, "You must own the NFT to list it.");

        listings[nextListingId] = Listing({
            nftContractAddress: _nftContractAddress,
            nftId: _nftId,
            seller: msg.sender,
            price: _price,
            deadline: block.timestamp + _deadline
        });

        listingOwners[nextListingId] = msg.sender;

        activeListingIds.push(nextListingId);

        emit NFTListed(nextListingId, msg.sender, _nftContractAddress, _nftId, _price, block.timestamp + _deadline);
        nextListingId++;
    }

    function buyNFT(uint256 _listingId) external payable whenNotPaused nonReentrant {
        require(msg.value > 0, "Sent value must be greater than zero.");

        Listing storage listing = listings[_listingId];
        require(listing.seller != address(0), "Listing does not exist.");
        require(block.timestamp <= listing.deadline, "This listing has expired.");
        require(msg.value == listing.price, "Sent value must be equal to the listing price.");

        uint256 royaltyAmount = (listing.price * royaltyPercentage) / 10000;
        uint256 platformFee = (listing.price * platformFeePercentage) / 10000;
        uint256 sellerAmount = listing.price - royaltyAmount - platformFee;

        IERC721 nftContract = IERC721(listing.nftContractAddress);
        require(nftContract.ownerOf(listing.nftId) == listing.seller, "Seller no longer owns the NFT.");

        nftContract.safeTransferFrom(listing.seller, msg.sender, listing.nftId);

        payable(listing.seller).transfer(sellerAmount);
        payable(royaltyAddress).transfer(royaltyAmount);
        payable(platformFeeAddress).transfer(platformFee);

        emit NFTSold(_listingId, listing.seller, msg.sender, listing.price);

        delete listings[_listingId];
        delete listingOwners[_listingId];
    }

    function cancelListing(uint256 _listingId) external nonReentrant {
        require(listingOwners[_listingId] == msg.sender, "Only the listing owner can cancel it.");
        
        delete listings[_listingId];
        delete listingOwners[_listingId];

        emit NFTDelisted(_listingId);
    }

    function pause() external onlyOwner nonReentrant {
        _pause();
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

    function getListingInfo(uint256 _listingId) external view returns (uint256, uint256, string memory) {
        Listing storage listing = listings[_listingId];
        require(listing.seller != address(0), "Listing does not exist.");

        string memory tokenMetadataLink = "";

        try IERC721Metadata(listing.nftContractAddress).tokenURI(listing.nftId) returns (string memory metadataLink) {
            tokenMetadataLink = metadataLink;
        } catch {}

        return (_listingId, listing.nftId, tokenMetadataLink);
    }
}
