// SPDX-License-Identifier: MIT

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

pragma solidity >=0.8.0 <0.9.0;

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title DSCEngine
 * @author Miguel Martinez
 * @notice This contract is the basse of DSC system. It handles all the logic for minting and burning DSC,
 * depositing and withdrawing collateral.
 * This contract is very loosely based on the MakerDAO DSS (DAI) system.
 * @dev The system is designed to be as minimal as possible, and have the tokens maintain a 1 token == $1 peg.
 * It is similar to DAI if DAI had no governance, no fees, and was only backed by wETH and wBTC.
 * Our DSC system should always be "overcallateralized".
 */
contract DSCEngine is ReentrancyGuard {
    ////////////////////
    ///    Errors    ///
    ////////////////////
    error DSCEngine__AmountLessOrEqualZero();
    error DSCEngine__TokenAddressesAndPriceFeedAddressMustBeSameLength();
    error DSCEngine__TokenNotUsedForCollateral();
    error DSCEngine__TransferFailed();
    error DSCEngine__BreakHealthFactor(uint256 userHealthFactor);
    error DSCEngine__MintFailed();

    ///////////////////////
    /// State Variables ///
    ///////////////////////
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint8 private constant LIQUIDATION_THRESHOLD = 50;
    uint8 private constant LIQUIDATION_PRECISION = 100;
    uint8 private constant MIN_HEALTH_FACTOR = 1;

    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
    mapping(address user => uint256 amountDscMinted) private s_DSCMinted;
    address[] private s_collateralTokens;

    DecentralizedStableCoin private immutable i_dscToken;

    ////////////////////
    ///    Events    ///
    ////////////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 amount);
    event DSCMinted(address indexed user, uint256 amount);

    ////////////////////
    ///   Modifiers  ///
    ////////////////////
    modifier MoreThanZero(uint256 amount) {
        if (amount <= 0) revert DSCEngine__AmountLessOrEqualZero();
        _;
    }

    modifier IsAllowToken(address token) {
        if (s_priceFeeds[token] == address(0)) revert DSCEngine__TokenNotUsedForCollateral();
        _;
    }

    ////////////////////
    ///   Functions  ///
    ////////////////////
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddress, address dscAddress) {
        if (tokenAddresses.length != priceFeedAddress.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressMustBeSameLength();
        }

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddress[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }

        i_dscToken = DecentralizedStableCoin(dscAddress);
    }

    /////////////////////////////////////
    /// External and Public Functions ///
    /////////////////////////////////////
    function depositCollateralAndMintDsc() external {}

    /**
     *
     * @param tokenCollateralAddress The address of the token to deposit as collateral
     * @param amountCollateral The amount of collateral to deposit
     */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        external
        MoreThanZero(amountCollateral)
        IsAllowToken(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);

        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!success) revert DSCEngine__TransferFailed();
    }

    /**
     *
     * @param amountDscToMint Amount of DSC to mint
     */
    function mintDsc(uint256 amountDscToMint) external MoreThanZero(amountDscToMint) nonReentrant {
        s_DSCMinted[msg.sender] += amountDscToMint;
        _revertIfHealthFactorIsBroken(msg.sender);
        emit DSCMinted(msg.sender, amountDscToMint);

        bool minted = i_dscToken.mint(msg.sender, amountDscToMint);
        if (!minted) revert DSCEngine__MintFailed();
    }

    function redeemCollateralForDsc() external {}

    function redeemCollateral() external {}

    function burnDsc() external {}

    function liquidate() external {}

    //////////////////////////////////////
    /// Internal and Private Functions ///
    //////////////////////////////////////

    ///////////////////////////////////////////
    /// Internal and Private view Functions ///
    ///////////////////////////////////////////

    /**
     *
     * @param user address of the user
     * @dev does not allow mint DSC if Healthfactor <1
     */
    function _revertIfHealthFactorIsBroken(address user) internal view {
        uint256 userHealthFactor = getHealthFactor(user);
        if (userHealthFactor < MIN_HEALTH_FACTOR) revert DSCEngine__BreakHealthFactor(userHealthFactor);
    }

    //////////////////////////////////////////
    /// External and Public view Functions ///
    //////////////////////////////////////////

    /**
     *
     * @param user address of the user
     * @dev return how close to liquidation a user is. If HealthFactor < 1, they can get liquidated.
     * need %200 overcollateralized
     */
    function getHealthFactor(address user) public view returns (uint256) {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = getAccountInformationUser(user);
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;

        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;
    }

    /**
     *
     * @param user address of the user
     * @return totalDscMinted total of DSC tokens minted by the user
     * @return collateralValueInUsd USD value of the user's collateral in the contract
     */
    function getAccountInformationUser(address user) public view returns (uint256, uint256) {
        uint256 totalDscMinted = s_DSCMinted[user];
        uint256 collateralValueInUsd = 0;

        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            collateralValueInUsd += getUsdValue(token, amount);
        }

        return (totalDscMinted, collateralValueInUsd);
    }

    /**
     *
     * @param token token contract address
     * @param amount amount of tokens
     * @dev Chainlink is used to get the current price of the token
     */
    function getUsdValue(address token, uint256 amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);

        //1ETH = $1000
        //returned value will be 1000 * 1e8
        (, int256 price,,,) = priceFeed.latestRoundData();

        //(1000 * 1e8 * 1e10) / 1e18
        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * amount) / PRECISION;
    }
}
