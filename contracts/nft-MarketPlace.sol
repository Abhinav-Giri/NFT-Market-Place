//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTMarketPlace is ERC721URIStorage {
   using Counters for Counters.Counter;

   //Keeps track of tokens recently minted
   Counters.Counter private _tokenIds;
   //keeps track of items sold on Marketplace
   Counters.Counter private _itemsSold;

   // owner is the owner of contract
   address payable owner;
   //fees charged by Marketplace to list on NFT
   uint256 listPrice = 0.01 ether;
   
   //Structure to store info about a listed token
   struct ListedTokenInfo{
       uint256 tokenId;
       address payable owner;
       address payable seller;
       uint256 price;
       bool currentlyListed;
   }

   //event is emitted on successfully listing token
   event TokenListedSuccessfully(uint256 indexed tokenId, address owner, address seller, uint256 price,bool CurrentlyListed);
   
   //mapping maps tokenId to tokenInfo and is helpful when retrieving details about a tokenId
   mapping(uint256 => ListedTokenInfo) private idToListedToken;

   constructor() ERC721("NFTMarketplace", "NMP"){
       owner = payable(msg.sender);

   }

   function updateListPrice(uint256 _listPrice) public payable{
       require(owner ==msg.sender, "Only owner can update list price");
       listPrice = _listPrice;
   }

   function getListPrice() public view returns(uint256) {
       return listPrice;
   }

   function getLatestIdToListedToken() public view returns(ListedTokenInfo memory){
       uint256 currentTokenId = _tokenIds.current();
       return idToListedToken[currentTokenId];
   }

   function getListedTokenForId(uint256 tokenId) public view returns(ListedTokenInfo memory){
       return idToListedToken[tokenId];
   }

   function getCurrentToken() public view returns (uint256) {
       return _tokenIds.current();
   }

   function createToken(string memory tokenURI, uint256 price) public payable returns(uint){
       _tokenIds.increment();

       uint256 newTokenId = _tokenIds.current();

       _safeMint(msg.sender, newTokenId);

       _setTokenURI(newTokenId, tokenURI);

       createListedToken(newTokenId, price);

       return newTokenId;
    
   }

   function createListedToken(uint256 tokenId, uint256 price) private{
    require(msg.value == listPrice, "Must be sending  correct list price");
    require(price > 0, "Make sure correct amount entry");

    idToListedToken[tokenId] = ListedTokenInfo(
                                 tokenId,
                                 payable(address(this)),
                                 payable(msg.sender),
                                 price,true);

    _transfer(msg.sender, address(this), tokenId);

    emit TokenListedSuccessfully(tokenId, address(this), msg.sender, price, true);

   }
   function getAllNFTs() public view returns(ListedTokenInfo[] memory){
       uint nftCount = _tokenIds.current();
       ListedTokenInfo[] memory tokens = new ListedTokenInfo[](nftCount);
       uint currentIndex = 0;

       for (uint i = 0; i < nftCount ; i++){
           
           tokens[currentIndex] = idToListedToken[i+1];
           currentIndex + 1;
       }
       return tokens;
   }

   function getMyNFTs() public view returns(ListedTokenInfo[]  memory){
       uint256 totalItemCount = _tokenIds.current();
       uint256 itemCount = 0;
       uint256 currentIndex = 0 ;

       for(uint i = 0; i<totalItemCount; i++){
           if(idToListedToken[i+1].owner == msg.sender || idToListedToken[i+1].seller == msg.sender){
               itemCount += 1; 
           }
       }
       ListedTokenInfo[] memory items = new ListedTokenInfo[] (itemCount);
       for(uint i = 0; i < totalItemCount ; i++){
           if(idToListedToken[i+1].owner == msg.sender || idToListedToken[i+1].seller == msg.sender){
               items[currentIndex] = idToListedToken[i+1];
               currentIndex += 1;
           }
       }
        return items;  
   }

   function executeSale(uint256 tokenId) public payable{
       uint256 price = idToListedToken[tokenId].price;
       address seller = idToListedToken[tokenId].seller;
       require(msg.value == price, "Do submit asking price");

       idToListedToken[tokenId].seller = payable(msg.sender);
       idToListedToken[tokenId].currentlyListed = true ;
       _itemsSold.increment();

        //Actually transfer the token to the new owner
       _transfer(address(this), seller,tokenId);
       //approve the marketplace to sell NFTs on your behalf
       approve(address(this),tokenId);

       //Transfer the listing fee to the marketplace creator
       payable(owner).transfer(listPrice);

        //Transfer the proceeds from the sale to the seller of the NFT
        payable(seller).transfer(msg.value);
   }


}