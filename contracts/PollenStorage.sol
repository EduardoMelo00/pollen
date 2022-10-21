//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract PollenStorage {


  uint256 public amount;
  address public owner;
  uint256 public tokenIndex;
  address public deployer;




  constructor(address _owner, uint256 _amount, uint256 _tokenIndex) {
    amount = _amount;
    owner = _owner;
    deployer = msg.sender;
    tokenIndex = _tokenIndex;
  }

  



}