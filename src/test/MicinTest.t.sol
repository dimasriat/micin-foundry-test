// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "lib/forge-std/src/Test.sol";
import {IERC20} from "lib/pancake-swap-periphery/contracts/interfaces/IERC20.sol";
import {WBNB_ADDRESS, CAKE_ADDRESS, PANCAKE_FACTORY, PANCAKE_ROUTER} from "src/test/bsc/Constants.sol";
import {IPancakeFactory} from "lib/pancake-swap-core/contracts/interfaces/IPancakeFactory.sol";
import {IPancakeRouter02} from "lib/pancake-swap-periphery/contracts/interfaces/IPancakeRouter02.sol";

contract MicinTest is Test {
    IERC20 wbnbToken;
    IERC20 cakeToken;
    IPancakeFactory factory;
    IPancakeRouter02 router;

    function setUp() public {
        wbnbToken = IERC20(WBNB_ADDRESS);
        cakeToken = IERC20(CAKE_ADDRESS);
        factory = IPancakeFactory(PANCAKE_FACTORY);
        router = IPancakeRouter02(PANCAKE_ROUTER);
    }

    function test_TokenName() public {
        assertEq(wbnbToken.name(), "Wrapped BNB");
        assertEq(cakeToken.name(), "PancakeSwap Token");
    }

    function testFail_PairAlreadyExist() public {
        factory.createPair(WBNB_ADDRESS, CAKE_ADDRESS);
    }

    function test_GetCAKEBNBPair() public {
        address pair = factory.getPair(WBNB_ADDRESS, CAKE_ADDRESS);
        assertEq(pair, 0x0eD7e52944161450477ee417DE9Cd3a859b14fD0);
    }

    function test_GetCAKEBNBPrice() public {
        address[] memory pairArray = new address[](2);
        pairArray[0] = CAKE_ADDRESS;
        pairArray[1] = WBNB_ADDRESS;
        uint256[] memory amounts = router.getAmountsOut(1 * 10**18, pairArray);
        emit log_named_uint("CAKE price in BNB", amounts[1]);
    }
}
