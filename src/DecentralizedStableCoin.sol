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

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error DecentralizedStableCoin__MustBeMoreThanZero();

/**
 * @title DecentralizedStableCoin
 * @author Miguel Martinez
 * @notice ERC20 implementation of our stablecoin system. It is governed by DSCEngine.
 * @dev Collateral: Exogenous (ETH & BTC)
 *      Minting: Algorithmic
 *      Relative Stability: Pegged to USD
 */
contract DecentralizedStableCoin is ERC20Burnable, Ownable {
    constructor() ERC20("DecentralizedStableCoin", "DSC") {}

    function burn(uint256 amount) public override onlyOwner {
        if (amount <= 0) revert DecentralizedStableCoin__MustBeMoreThanZero();
        super.burn(amount);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        if (amount <= 0) revert DecentralizedStableCoin__MustBeMoreThanZero();
        _mint(to, amount);
    }
}
