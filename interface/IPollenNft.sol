pragma solidity ^0.8.0;

interface IPollenNft {

function createToken(address sender) external returns (uint256 id);

function balanceOf(address sender) external view returns (uint256 id); 

function ownerOf(uint256 tokenId) external view returns ( address sender);

function burn(uint256 tokenId) external;
   

}