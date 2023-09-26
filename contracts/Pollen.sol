//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/AggregatorV3Interface.sol";
import "../interface/IPollenNft.sol";
import "../interface/ICErc20.sol";
import "../interface/IDateTime.sol";
import "../interface/IUniswapPrice.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract Pollen is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    IERC20Upgradeable public DAI;
    IPollenNft public PollenNFT;
    IERC20Upgradeable public xrz;
    AggregatorV3Interface public DAIPriceFeed;
    IDateTime public dateTime;
    IUniswapPrice public uniswapPrice;
    AggregatorV3Interface public dollarPrice;

    address constant cTokenAddress = 0x0545a8eaF7ff6bB6F708CbB544EA55DBc2ad7b2a; //goerli
    uint256 rewardFactor = 1; // 1 = 1 per cent
    uint256 constant rewardInterval = 86400 / 24 / 60; // 86400 = 1 day
    address  pollenVault = 0x986039D42D25204339bD352Bc2b1E13dC87C8521;
    uint256 stakeOption;
    uint256[] totalNFT;
    uint256[] totalTVL;
    ICErc20 cToken;



    struct StakedToken {
        uint256 tokenId;
        uint256 amount;
        uint256 startTimestamp;
        uint256 lastHarvestTimestamp;
        uint256 period;
    }

    struct Months {
        uint256 currentMonth;
        uint256 amount;
    }

    event Harvest(uint256 tokenId, uint256 amount);
    event Staked(
        uint256 tokenId,
        uint256 amount,
        uint256 period,
        string tokenUri
    );
    event Unstaked(address owner, uint256 tokenIndexId);

    mapping(uint256 => StakedToken) rewards;
    mapping(uint256 => Months) months;

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;

    function initialize() public initializer {
        dateTime = IDateTime(0xC1aC1E61454c23cA1721266b3b94353916ebDcb4); //  goerli
        xrz = IERC20Upgradeable(0x13a7DE1D9D624f953DC0Ba525A9a7affff57ee6d); // goerli
        DAI = IERC20Upgradeable(0x2899a03ffDab5C90BADc5920b4f53B0884EB13cC); //goerli
        PollenNFT = IPollenNft(0x8cC07c6b2e168612DaB23175F87a26e9B8d9fC5B); //  goerli
        uniswapPrice = IUniswapPrice(
            0x7a9a7A8573fe818B3B58371F2298E9330eEa59a2
        ); // mainnet
        DAIPriceFeed = AggregatorV3Interface(
            0x0d79df66BE487753B02D015Fb622DED7f0E9798d //goerli
        );
        dollarPrice = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        ); //goerli
        cToken = ICErc20(cTokenAddress); //atualizado

        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
    }

    ///@dev required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function setPollenNFT(address _pollenNFT) public onlyOwner {
        PollenNFT = IPollenNft(_pollenNFT);
    }

    function setRewardFactor(uint256 _rewardFactor) public onlyOwner {
        rewardFactor = _rewardFactor;
    }

    function setPollenVault(address _pollenVault) public onlyOwner {
        pollenVault = _pollenVault;
    }


    function stake(
        uint256 amount,
        uint256 period,
        string memory tokenUri
    ) public whenNotPaused nonReentrant {
        uint256 newItemId;
        uint256 currentMonth;

        require(amount > 0, "You need to input an mount bigger than 0");

        bool success = DAI.approve(cTokenAddress, amount);

        require(success, "not approved");

        DAI.transferFrom(msg.sender, address(this), amount);

        currentMonth = getMonth(block.timestamp);

        newItemId = PollenNFT.createToken(msg.sender, tokenUri);

        months[newItemId] = Months(currentMonth, amount);

        rewards[newItemId] = StakedToken(
            newItemId,
            amount,
            block.timestamp,
            block.timestamp,
            period
        );

        totalNFT.push(newItemId);
        totalTVL.push(currentMonth);


        // Transfer to compound 
        // sender -> address(this)


        cToken.mint(amount);

        emit Staked(newItemId, amount, period, tokenUri);
    }

    function calculateReward(uint256 tokenIndex) public view returns (uint256) {
        StakedToken memory staked = rewards[tokenIndex];
        uint256 rewardPriceUsd = (((staked.amount *
            getLatestEthPrice(DAIPriceFeed)) / 1e8) *
            rewardFactor *
            (block.timestamp - staked.lastHarvestTimestamp)) /
            100 /
            rewardInterval;

        return
            rewardPriceUsd /
            getLastXrzPrice(0x2899a03ffDab5C90BADc5920b4f53B0884EB13cC);
    }

    function getReward(address _owner, uint256 tokenIndex) public {
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

        for (uint256 i = 0; i < ownedNFTs.length; i++) {
            getReward(_owner, ownedNFTs[i].tokenId);
        }
    }

    function getAllRewards(address _owner) public view returns (uint256) {
        uint256 _totalRewards;

        IPollenNft.OwnedNFT[] memory ownedNFTs = PollenNFT.getNFTsByOwner(
            _owner
        );

        for (uint256 i = 0; i < ownedNFTs.length; i++) {
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

        for (uint256 i = 1; i <= allOwnedNFTs.length; i++) {
            if (rewards[allOwnedNFTs[i - 1].tokenId].startTimestamp > 0) {
                ownedNFTs[currentItemsListIndex].tokenUri = allOwnedNFTs[i - 1]
                    .tokenUri;
                ownedNFTs[currentItemsListIndex].tokenId = allOwnedNFTs[i - 1]
                    .tokenId;
                currentItemsListIndex++;
            }
        }

        return ownedNFTs;
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

        // Return amount in DAI - TOTALTVL + PROFIT(from compound) - de acordo o tempo 
        uint256 totalStakedComp = cToken.balanceOfUnderlying(address(this));
        require(
            PollenNFT.balanceOf(_owner) >= 1,
            "You don't have any Pollen NFT amount"
        );

        uint256 returnTotalTVL = getTotalTVL();

        uint256 preProfit = totalStakedComp - returnTotalTVL;

        uint256 profitCalc = (preProfit * staked.amount) / returnTotalTVL;

        uint256 returnTotalunstake = profitCalc + staked.amount;

        cToken.redeemUnderlying(returnTotalunstake);

        rewards[tokenIndex].startTimestamp = 0;
        rewards[tokenIndex].lastHarvestTimestamp = 0;
        rewards[tokenIndex].amount = 0;
        PollenNFT.burn(tokenIndex);

        getReward(_owner, tokenIndex);
        DAI.transfer(msg.sender, staked.amount);
        DAI.transfer(pollenVault, profitCalc);

        emit Unstaked(_owner, tokenIndex);
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

    function getTotalStakedFromUser(address _owner)
        public
        view
        returns (uint256)
    {
        uint256 _totalStaked;

        IPollenNft.OwnedNFT[] memory ownedNFTs = PollenNFT.getNFTsByOwner(
            _owner
        );

        for (uint256 i = 0; i < ownedNFTs.length; i++) {
            _totalStaked += rewards[ownedNFTs[i].tokenId].amount;
        }
        return _totalStaked;
    }

    function getTimeStamp(uint256 tokenIndex) public view returns (uint256) {
        return rewards[tokenIndex].startTimestamp;
    }

    function getLookup(uint256 tokenIndex) public view returns (uint256) {
        return rewards[tokenIndex].period;
    }

    function getBalanceOf() public view returns (uint256) {
        return cToken.balanceOf(address(this));
    }

    function getTotalTVL() public view returns (uint256) {
        uint256 _totalTVL;

        for (uint256 i = 0; i < totalNFT.length; i++) {
            uint256 id = totalNFT[i];
            _totalTVL += rewards[id].amount;
        }
        return _totalTVL;
    }

    function getTotalTVLGraph(uint256 month) public view returns (uint256) {
        uint256 _totalAmountbyMonth;

        for (uint256 i = 0; i < totalNFT.length; i++) {
            uint256 id = totalNFT[i];

            if (month == months[id].currentMonth) {
                _totalAmountbyMonth += months[id].amount;
            }
        }

        return _totalAmountbyMonth;
    }

    function getTotalTVLOwner(uint256 month, address _owner)
        public
        view
        returns (uint256)
    {
        uint256 _totalAmountbyMonth;
        IPollenNft.OwnedNFT[] memory ownedNFTs = PollenNFT.getNFTsByOwner(
            _owner
        );

        for (uint256 i = 0; i < totalNFT.length; i++) {
            uint256 id = totalNFT[i];

            for (uint256 y = 0; y < ownedNFTs.length; y++) {
                if (
                    month == months[id].currentMonth &&
                    ownedNFTs[y].tokenId == id
                ) {
                    _totalAmountbyMonth += months[id].amount;
                }
            }
        }

        return _totalAmountbyMonth;
    }

    function getTotalNFT() public view returns (uint256) {
        return totalNFT.length;
    }

    function getMonth(uint256 timestamp) public view returns (uint256) {
        return dateTime.getMonth(timestamp);
    }

    function getLastXrzPrice(address tokenIn)
        public
        view
        returns (uint256 amount)
    {
        uint256 _lastprince;

        _lastprince = uniswapPrice.estimateAmountOut(tokenIn, 1, 10);

        return _lastprince;
    }
}
