//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "../interface/AggregatorV3Interface.sol";

contract PollenNft is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ERC721URIStorageUpgradeable
{
    struct OwnedNFT {
        uint256 tokenId;
        string tokenUri;
    }

    string public URI = "https://jsonkeeper.com/b/W90P";
    uint256 public _newItemID;

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;

    function initialize() public initializer {
        __ERC721_init("Pollen NFT", "PNFT");
        __Ownable_init();
    }

    ///@dev required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}

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
