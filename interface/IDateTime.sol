//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDateTime {
    
   function getMonth(uint timestamp) external view returns (uint month);
   
}
