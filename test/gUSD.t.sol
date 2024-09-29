// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {gUSD} from "src/gUSD.sol";

contract gUSDTest is Test {
    gUSD gusd;
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    uint256 AMOUNT_TO_GIVE = 10 ether;

    function setUp() external {
        gusd = new gUSD();

        startHoax(user1, AMOUNT_TO_GIVE);
    }

    function testFoo() external {
        gusd.mintGUSD{value: 1.016 ether}(21e8);
        console.log(gusd.balanceOf(user1));

        // get collateral
        console.log("user collateral", gusd.userCollateral(user1));

        // get health factor
        uint256 userHealth = gusd.getHealthFactor(user1);
        console.log("user health", userHealth);
    }
}

// before
// Logs:
//  price: 264678613930
//   _amountToMint: 2100000000
//   ethRequired: 15868301324529306
//   2100000000
//   user collateral 16000000000000000
//   user health 1008299481428571428

// after
// Logs:
//  price: 264678613930
//  _amountToMint: 2100000000
//  ethRequired: 15868301324529306
//  2100000000
//  user collateral 1016000000000000000
//  user health 64027017083809523809  this is a much better health factor than the one above [0.016 eth vs 1.016 eth]
