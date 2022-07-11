//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interface/AggregatorV3Interface.sol";

contract PollenNft is ERC721URIStorage {
    

    ERC721 public nft;

    string public URI =  "https://jsonkeeper.com/b/W90P";
    uint256 public _newItemID;

    using Counters for Counters.Counter; 
    Counters.Counter private _tokenIds;

    constructor() ERC721("Pollen NFT", "PNFT") {

    }

    function createToken(address sender) public returns (uint) {
        _tokenIds.increment();
         _newItemID = _tokenIds.current();

        _mint(sender, _newItemID);
        _setTokenURI(_newItemID, URI);
        return _newItemID;  
    }


    function burn(uint256 _tokenId) public {
        _burn(_tokenId);
    }

}
