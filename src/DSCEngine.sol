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

    ///////////////////////
    /// State Variables ///
    ///////////////////////
    mapping(address => address) private s_priceFeeds; //token -> priceFeed
    DecentralizedStableCoin private immutable i_dscToken;

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
        }

        i_dscToken = DecentralizedStableCoin(dscAddress);
    }

    //////////////////////////
    /// External Functions ///
    //////////////////////////
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
    {}

    function redeemCollateralForDsc() external {}

    function redeemCollateral() external {}

    function mintDsc() external {}

    function burnDsc() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}
}
