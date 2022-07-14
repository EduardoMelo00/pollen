//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../interface/AggregatorV3Interface.sol";

contract PollenNft is ERC721URIStorage {
    struct OwnedNFT {
        uint256 tokenId;
        string tokenUri;
    }

    string public URI = "https://jsonkeeper.com/b/W90P";
    uint256 public _newItemID;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("Pollen NFT", "PNFT") {}

    function createToken(address _sender) public returns (uint256) {
        _tokenIds.increment();
        _newItemID = _tokenIds.current();

        _mint(_sender, _newItemID);
        _setTokenURI(_newItemID, URI);
        return _newItemID;
    }

    function getNFTsByOwner(address _owner)
        public
        view
        returns (OwnedNFT[] memory)
    {
        uint256 ownerBalance = balanceOf(_owner);
        OwnedNFT[] memory ownedNFTs = new OwnedNFT[](ownerBalance);
        uint256 currentItemsListIndex = 0;

        for (uint256 i = 1; i <= _tokenIds.current(); i++) {
            if (currentItemsListIndex >= ownerBalance) {
                break;
            }
            if (_exists(i) && ownerOf(i) == _owner) {
                ownedNFTs[currentItemsListIndex].tokenId = i;
                ownedNFTs[currentItemsListIndex].tokenUri = tokenURI(i);
                currentItemsListIndex++;
            }
        }

        return ownedNFTs;
    }

    function burn(uint256 _tokenId) public {
        _burn(_tokenId);
    }
}
