// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMALS = 8;
    int256 public constant ETH_USD_PRICE = 2000e8;
    int256 public constant BTC_USD_PRICE = 1000e8;

    uint8 public constant CHAINID_GOERLI = 5;
    uint32 public constant CHAINID_SEPOLIA = 11155111;
    uint8 public constant CHAINID_ETHEREUM = 1;
    uint16 public constant CHAINID_GANACHE = 5777;

    struct NetworkConfig {
        address weth;
        address wbtc;
        address wethUsdPriceFeed;
        address wbtcUsdPriceFeed;
        uint256 deployerKey;
    }

    constructor() {
        if (block.chainid == CHAINID_GOERLI) activeNetworkConfig = getGoerliEthConfig();
        else if (block.chainid == CHAINID_SEPOLIA) activeNetworkConfig = getSepoliaEthConfig();
        else if (block.chainid == CHAINID_ETHEREUM) activeNetworkConfig = getMainEthConfig();
        else if (block.chainid == CHAINID_GANACHE) activeNetworkConfig = getOrCreateGanacheChainEthConfig();
        else activeNetworkConfig = getOrCreateAnvilChainEthConfig();
    }

    function getGoerliEthConfig() public view returns (NetworkConfig memory) {
        address weth = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
        address wbtc = 0x0000000000000000000000000000000000000000;
        address wethUsdPriceFeed = 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e;
        address wbtcUsdPriceFeed = 0xA39434A63A52E749F02807ae27335515BA4b07F7;
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        NetworkConfig memory goerliConfig = NetworkConfig(weth, wbtc, wethUsdPriceFeed, wbtcUsdPriceFeed, deployerKey);
        return goerliConfig;
    }

    function getSepoliaEthConfig() public view returns (NetworkConfig memory) {
        address weth = 0xdd13E55209Fd76AfE204dBda4007C227904f0a81;
        address wbtc = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
        address wethUsdPriceFeed = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
        address wbtcUsdPriceFeed = 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43;
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        NetworkConfig memory sepoliaConfig = NetworkConfig(weth, wbtc, wethUsdPriceFeed, wbtcUsdPriceFeed, deployerKey);
        return sepoliaConfig;
    }

    function getMainEthConfig() public view returns (NetworkConfig memory) {
        address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
        address wethUsdPriceFeed = 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c;
        address wbtcUsdPriceFeed = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        NetworkConfig memory mainConfig = NetworkConfig(weth, wbtc, wethUsdPriceFeed, wbtcUsdPriceFeed, deployerKey);
        return mainConfig;
    }

    function getOrCreateGanacheChainEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.weth != address(0)) return activeNetworkConfig;
        uint256 deployerKey = vm.envUint("GANACHE_PRIVATE_KEY");

        vm.startBroadcast();
        ERC20Mock wethMock = new ERC20Mock();
        ERC20Mock wbtcMock = new ERC20Mock();
        MockV3Aggregator ethUsdPriceFeed = new MockV3Aggregator(
            DECIMALS,
            ETH_USD_PRICE
        );
        MockV3Aggregator btcUsdPriceFeed = new MockV3Aggregator(
            DECIMALS,
            BTC_USD_PRICE
        );
        vm.stopBroadcast();

        NetworkConfig memory testConfig = NetworkConfig(
            address(wethMock), address(wbtcMock), address(ethUsdPriceFeed), address(btcUsdPriceFeed), deployerKey
        );
        return testConfig;
    }

    function getOrCreateAnvilChainEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.weth != address(0)) return activeNetworkConfig;
        uint256 deployerKey = vm.envUint("ANVIL_PRIVATE_KEY");

        vm.startBroadcast();
        ERC20Mock wethMock = new ERC20Mock();
        ERC20Mock wbtcMock = new ERC20Mock();
        MockV3Aggregator ethUsdPriceFeed = new MockV3Aggregator(
            DECIMALS,
            ETH_USD_PRICE
        );
        MockV3Aggregator btcUsdPriceFeed = new MockV3Aggregator(
            DECIMALS,
            BTC_USD_PRICE
        );
        vm.stopBroadcast();

        NetworkConfig memory testConfig = NetworkConfig(
            address(wethMock), address(wbtcMock), address(ethUsdPriceFeed), address(btcUsdPriceFeed), deployerKey
        );
        return testConfig;
    }
}
