//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IUniswapPrice {

    function estimateAmountOut( address tokenIn, uint128 amountIn, uint32 secondsAgo) external view returns (uint256 amountOut);

}
