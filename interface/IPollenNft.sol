//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;




interface IPollenNft {


struct OwnedNFT {
        uint256 tokenId;
        string tokenUri;
    }


    function createToken(address sender, string memory tokenUri) external returns (uint256 id);

    function balanceOf(address sender) external view returns (uint256 id);

    function ownerOf(uint256 tokenId) external view returns (address sender);

    function burn(uint256 tokenId) external;

    function getNFTsByOwner(address _owner) external view returns(OwnedNFT[] memory);

}
