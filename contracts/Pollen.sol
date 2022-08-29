//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interface/AggregatorV3Interface.sol";
import "../interface/IPollenNft.sol";
import "../interface/ICErc20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../utils/DateTime.sol";

contract Pollen is ReentrancyGuard, Pausable, Ownable {
    string public URI = "https://jsonkeeper.com/b/W90P";
    IERC20 public DAI;
    IPollenNft public PollenNFT;
    IERC20 public xrz;
    AggregatorV3Interface public DAIPriceFeed;

    DateTime public _dateTime;

    uint256 public rewardFactor = 1; // 1 = 1 per cent
    uint256 public rewardInterval = 86400 / 24 / 60; // 86400 = 1 day
    uint256 public xrzPrice = 25; // DUX price
    address public pollenVault = 0x3A9ed39105d4e1a0719dAa16343A5b855B01100F;
    ICErc20 public cToken;
    uint256 public stakeOption;
    address public cTokenAddress = 0xbc689667C13FB2a04f09272753760E38a95B998C;
    uint256 public rate;
    uint256[] public totalNFT;

    struct StakedToken {
        uint256 tokenId;
        uint256 amount;
        uint256 startTimestamp;
        uint256 lastHarvestTimestamp;
        uint256 period;
    }

    event Harvest(uint256 tokenId, uint256 amount);

    mapping(uint256 => StakedToken) public rewards;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() {
        xrz = IERC20(0xDEcEF803dC694341Cf2dA8A1efB67AD81B397519); //atualizado
        DAI = IERC20(0x31F42841c2db5173425b5223809CF3A38FEde360); //atualizado
        PollenNFT = IPollenNft(0x424D16025640B2D823c06ED6333Ae6b802f2584F); // atualizado
        DAIPriceFeed = AggregatorV3Interface(
            0x2bA49Aaa16E6afD2a993473cfB70Fa8559B523cF
        );
        cToken = ICErc20(cTokenAddress); //atualizado
        //rate = cToken.exchangeRateCurrent();
    }

    function stake(uint256 amount, uint256 period)
        public
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        uint256 newItemId;

        require(amount > 0, "You need to input an mount bigger than 0");

        // Approve transfer on the ERC20 contract
        bool success = DAI.approve(cTokenAddress, 99999999999999999999);

        require(success, "not approved");
        DAI.transferFrom(msg.sender, address(this), amount);

        newItemId = PollenNFT.createToken(msg.sender);
        rewards[newItemId] = StakedToken(
            newItemId,
            amount,
            block.timestamp,
            block.timestamp,
            period
        );

        totalNFT.push(newItemId);

        // Mint cTokens
        uint256 mintResult = cToken.mint(amount);
        return mintResult;
    }

    function calculateReward(uint256 tokenIndex) public view returns (uint256) {
        StakedToken memory staked = rewards[tokenIndex];
        // uint256 rewardPriceUsd = (staked.amount * getLatestEthPrice(DAIPriceFeed) / 1e8 * rewardFactor * (block.timestamp - staked.lastHarvestTimestamp)) / 100 / rewardInterval; rinkeby
        uint256 rewardPriceUsd = (((staked.amount * 100256892) / 1e8) *
            rewardFactor *
            (block.timestamp - staked.lastHarvestTimestamp)) /
            100 /
            rewardInterval; // ropsten

        return rewardPriceUsd / xrzPrice / 100;
    }

    function getBalanceUnder(address sender) public returns (uint256) {
        uint tokens = cToken.balanceOfUnderlying(sender);
        return tokens;
    }

    function getReward(address _owner, uint256 tokenIndex) public {
        // require(PollenNFT.ownerOf(tokenIndex) == _owner,"You don't own any Pollen NFT." );
        require(
            PollenNFT.balanceOf(_owner) >= 1,
            "You don't have any Pollen NFT amount"
        );
        uint256 reward = calculateReward(tokenIndex);
        rewards[tokenIndex].lastHarvestTimestamp = block.timestamp;
        xrz.transfer(msg.sender, reward);
        emit Harvest(tokenIndex, reward);
    }

    function claimAll(address _owner) public {
        IPollenNft.OwnedNFT[] memory ownedNFTs = PollenNFT.getNFTsByOwner(
            _owner
        );

        for (uint i = 0; i < ownedNFTs.length; i++) {
            getReward(_owner, ownedNFTs[i].tokenId);
        }
    }

    function getAllRewards(address _owner) public view returns (uint256) {
        uint256 _totalRewards;

        IPollenNft.OwnedNFT[] memory ownedNFTs = PollenNFT.getNFTsByOwner(
            _owner
        );

        for (uint i = 0; i < ownedNFTs.length; i++) {
            _totalRewards += calculateReward(ownedNFTs[i].tokenId);
        }

        return _totalRewards;
    }

    function getAllNfts(address _owner)
        public
        view
        returns (IPollenNft.OwnedNFT[] memory)
    {
        IPollenNft.OwnedNFT[] memory allOwnedNFTs = PollenNFT.getNFTsByOwner(
            _owner
        );
        IPollenNft.OwnedNFT[] memory ownedNFTs = new IPollenNft.OwnedNFT[](
            allOwnedNFTs.length
        );

        uint256 currentItemsListIndex = 0;

        for (uint256 i = 0; i < allOwnedNFTs.length; i++) {
            if (rewards[allOwnedNFTs[i].tokenId].startTimestamp > 0) {
                ownedNFTs[currentItemsListIndex].tokenId = allOwnedNFTs[i].tokenId;
                ownedNFTs[currentItemsListIndex].tokenUri = allOwnedNFTs[i].tokenUri;
                currentItemsListIndex++;
            }
        }

        return ownedNFTs;
    }

    function reedemCompound(uint256 _amount, uint256 tokenIndex)
        public
        returns (uint256)
    {
        StakedToken memory staked = rewards[tokenIndex];

        uint256 value = cToken.redeemUnderlying(rewards[tokenIndex].amount);

        return value;
    }

    function unstake(address _owner, uint256 tokenIndex)
        public
        whenNotPaused
        nonReentrant
    {
        StakedToken memory staked = rewards[tokenIndex];
        if (staked.period == 1) {
            stakeOption = staked.startTimestamp + 3 minutes;
        } else {
            stakeOption = staked.startTimestamp + 10 minutes;
        }
        require(block.timestamp > stakeOption, "You still cannot withdraw");

        uint256 totalStakedComp = cToken.balanceOfUnderlying(address(this));
        cToken.redeemUnderlying(totalStakedComp);

        uint256 pollenProfit = totalStakedComp - staked.amount;

        DAI.transfer(msg.sender, rewards[tokenIndex].amount);

        DAI.transfer(pollenVault, pollenProfit);

        getReward(_owner, tokenIndex);
        rewards[tokenIndex].startTimestamp = 0;
        rewards[tokenIndex].lastHarvestTimestamp = 0;
        rewards[tokenIndex].amount = 0;
        PollenNFT.burn(tokenIndex);
    }

    function getLatestEthPrice(AggregatorV3Interface _tokenPriceFeed)
        public
        view
        returns (uint256 latestTokenPrice)
    {
        (, int256 price, , , ) = _tokenPriceFeed.latestRoundData();

        latestTokenPrice = uint256(price);

        return latestTokenPrice;
    }

    function getTotalStaked(uint256 tokenIndex) public view returns (uint256) {
        return rewards[tokenIndex].amount;
    }

    function getTimeStamp(uint256 tokenIndex) public view returns (uint256) {
        return rewards[tokenIndex].startTimestamp;
    }

    function getLookup(uint256 tokenIndex) public view returns (uint256) {
        return rewards[tokenIndex].period;
    }

    function getExRate() public view returns (uint256) {
        return cToken.exchangeRateCurrent();

        //  uint256 total =  (cToken.balanceOf(sender) * exchangeRateMantissa);

        //  return exchangeRateMantissa;
    }

    function getBalanceOf() public view returns (uint256) {
        return cToken.balanceOf(address(this));
    }

    function getTotalTVL() public view returns (uint256) {
        uint256 _totalTVL;

        for (uint i = 0; i < totalNFT.length; i++) {
            uint256 id = totalNFT[i];
            _totalTVL += rewards[id].amount;
        }
        return _totalTVL;
    }

    // function getMonth(uint256 tokenIndex) public view returns(uint8) {
    //     return rewards[tokenIndex].month;
    // }

    function getTotalNFT() public view returns (uint256) {
        return totalNFT.length;
    }
}
