//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICErc20 {
    function mint(uint256) external returns (uint256);

    function exchangeRateCurrent() external view returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);

    function balanceOfUnderlying(address sender) external returns (uint);

    function balanceOf(address sender) external view returns(uint256);

}
