// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {AggregatorV3Interface} from "lib/chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {Strings} from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

// remove this later because it wont deploy to mainnet with this and it wont give any reasons what the problem is
import {Test, console} from "forge-std/Test.sol";

// this is just like DAI where the the gUSD is over collateralized-stablecoin
// what is the optimal collateralization ratio?
// does it hold yield by lending to lending plataforms?
// what types of collateral are accepted? [for now lets start with ETH]

contract gUSD is ERC20, ReentrancyGuard, Test {
    /****************************************
     *           global variables           *
     ****************************************/
    AggregatorV3Interface private priceFeed;
    address eth_usd = 0x694AA1769357215DE4FAC081bf1f309aDC325306;

    mapping(address user => uint256 collateralDeposited) public userCollateral;

    constructor() ERC20("gUSD", "gUSD") {}

    /****************************************
     *               functions              *
     ****************************************/

    // mint gUSD
    function mintGUSD(uint256 _amountToMint) public payable nonReentrant {
        // Fetch the price of ETH in USD (with 8 decimals)
        uint256 price = uint256(getTokenPrice());

        // Calculate the required ETH collateral (200% of the gUSD amount)
        uint256 ethRequired = (_amountToMint * 2 * 1e18) / price;

        // Ensure the user has sent enough ETH as collateral
        require(msg.value >= ethRequired, "insufficient ETH collateral");

        // Update the user's collateral balance
        userCollateral[msg.sender] += msg.value;

        // Mint the gUSD equivalent to the requested amount
        _mint(msg.sender, _amountToMint);

        // Log the details for debugging
        console.log("price:", price);
        console.log("_amountToMint:", _amountToMint);
        console.log("ethRequired:", ethRequired);
    }

    // burn gUSD
    function burnGUSD(uint256 _amountToBurn) public nonReentrant {
        // Fetch the price of ETH in USD (with 8 decimals)
        uint256 price = uint256(getTokenPrice());

        // Calculate the required ETH collateral (200% of the gUSD amount)
        uint256 ethRequired = (_amountToBurn * 2 * 1e18) / price;

        // Ensure the user has enough collateral to burn the gUSD
        require(
            userCollateral[msg.sender] >= ethRequired,
            "insufficient collateral"
        );

        // Update the user's collateral balance
        userCollateral[msg.sender] -= ethRequired;

        // Burn the gUSD
        _burn(msg.sender, _amountToBurn);

        // Log the details for debugging
        console.log("price:", price);
        console.log("_amountToBurn:", _amountToBurn);
        console.log("ethRequired:", ethRequired);
    }

    //  param : address _tokenAddress  , for later
    function getTokenPrice() public returns (int256) {
        priceFeed = AggregatorV3Interface(eth_usd); // for now lets start with ETHm then we can add more tokens
        (, int256 price, , uint256 timeStamp, ) = priceFeed.latestRoundData();

        require(timeStamp > 0, "stale data");

        return price;
    }

    // check health factor
    function getHealthFactor(address user) public returns (uint256) {
        uint256 collateralValue = (userCollateral[user] *
            uint256(getTokenPrice())) / 1e18; // USD value of collateral
        uint256 debtValue = balanceOf(user); // Amount of gUSD minted
        return (collateralValue * 1e18) / (debtValue * 2); // 200% ratio
    }

    function decimals() public view virtual override returns (uint8) {
        return 8; // later do with a different number to see change the factors accordingly
    }

    // liquidate
}
