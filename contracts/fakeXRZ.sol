// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FAKEXRZ is ERC20 {
    constructor() ERC20("FAKEXRZ", "FXRZ") {
        _mint(msg.sender, 10000000000 * (10**uint256(decimals())));
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }
}
