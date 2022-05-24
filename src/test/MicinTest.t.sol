// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "lib/forge-std/src/Test.sol";
import {IERC20} from "lib/pancake-swap-periphery/contracts/interfaces/IERC20.sol";
import {WBNB_ADDRESS, CAKE_ADDRESS, PANCAKE_FACTORY, PANCAKE_ROUTER} from "src/test/bsc/Constants.sol";
import {IPancakeFactory} from "lib/pancake-swap-core/contracts/interfaces/IPancakeFactory.sol";
import {IPancakeRouter02} from "lib/pancake-swap-periphery/contracts/interfaces/IPancakeRouter02.sol";

import {GhozaliToken} from "../tokens/Ghozali.sol";

contract User {
    IPancakeRouter02 router;
    GhozaliToken token;

    constructor(IPancakeRouter02 _router, GhozaliToken _token) {
        router = _router;
        token = _token;
    }

    function addLiquidity(uint256 amountETH, uint256 amountToken) public {
        router.addLiquidityETH(
            token,
            amountETH,
            amountToken,
            amountETH,
            address(this),
            block.timestamp + 1000
        );
    }

    function buyToken(uint256 amountETHInEther) public {
        address[] memory path = new address[](2);
        path[0] = WBNB_ADDRESS;
        path[1] = address(token);
        router.swapExactETHForTokens{value: amountETHInEther}(
            0,
            path,
            address(this),
            block.timestamp + 1000
        );
    }
}

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

    function test_DeployContract() public {
        GhozaliToken token = new GhozaliToken();
        emit log_named_string("token name", token.name());
        emit log_named_string("token symbol", token.symbol());
        emit log_named_address("token address", address(token));
        emit log_named_uint("balance of this", address(this).balance / 1 ether);
    }

    function test_AddLiquidity() public {
        GhozaliToken token = new GhozaliToken();
        User dev = new User(router, token);
        address(dev).call{value: 10 ether}("");

        User me = new User(router, token);
        dev.addLiquidity(1 ether, 1000000 ether);
    }
}
