//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../interface/AggregatorV3Interface.sol";

contract PollenNft is
    Initializable,
    UUPSUpgradeable,
    ERC721URIStorageUpgradeable,
    AccessControlUpgradeable
{
    struct OwnedNFT {
        uint256 tokenId;
        string tokenUri;
    }

    uint256 public _newItemID;

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function initialize() public initializer {
        __ERC721_init("Pollen NFT", "PNFT");
        __AccessControl_init();

        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    ///@dev required by the OZ UUPS module
    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(MINTER_ROLE)
    {}

    function createToken(address _sender, string memory _tokenUri)
        public
        virtual
        onlyRole(MINTER_ROLE)
        returns (uint256)
    {
        _tokenIds.increment();
        _newItemID = _tokenIds.current();

        _mint(_sender, _newItemID);
        _setTokenURI(_newItemID, _tokenUri);
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

    function getCurrentTokenId() public view returns (uint256) {
        return _tokenIds.current();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // used to grant minter role to the Pollen Contract after deploying it
    function grantMinterRole(address _to)
        public
        virtual
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _grantRole(MINTER_ROLE, _to);
    }
}
