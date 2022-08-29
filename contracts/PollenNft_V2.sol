// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PollenNft.sol";

contract PollenNftV2 is PollenNft {
    ///@dev increments the slices when called

    function createToken(address _sender) public override returns (uint256) {
        _newItemID = getCurrentTokenId() + 100;

        _mint(_sender, _newItemID);
        _setTokenURI(_newItemID, URI);
        return _newItemID;
    }

    ///@dev returns the contract version
    function pizzaVersion() external pure returns (uint256) {
        return 2;
    }
}
