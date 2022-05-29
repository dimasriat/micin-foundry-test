// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "lib/forge-std/src/Test.sol";
import {DummyToken} from "src/tokens/DummyToken.sol";
import {WBNB_ADDRESS, PANCAKE_FACTORY, PANCAKE_ROUTER} from "src/test/bsc/Constants.sol";
import {IPancakeFactory} from "lib/pancake-swap-core/contracts/interfaces/IPancakeFactory.sol";
import {IPancakePair} from "lib/pancake-swap-core/contracts/interfaces/IPancakePair.sol";
import {IPancakeRouter02} from "lib/pancake-swap-periphery/contracts/interfaces/IPancakeRouter02.sol";
import {IERC20} from "lib/pancake-swap-periphery/contracts/interfaces/IERC20.sol";

contract User {
    IPancakeFactory factory = IPancakeFactory(PANCAKE_FACTORY);
    IPancakeRouter02 router = IPancakeRouter02(PANCAKE_ROUTER);
    IPancakePair pair;
    DummyToken token;

    function deployToken() public returns (DummyToken) {
        token = new DummyToken();
        return token;
    }

    function addLiquidity(uint256 amountETH)
        public
        payable
        returns (IPancakePair)
    {
        token.approve(address(router), token.balanceOf(address(this)));
        router.addLiquidityETH{value: amountETH}(
            address(token),
            token.balanceOf(address(this)),
            token.balanceOf(address(this)),
            amountETH,
            address(this),
            block.timestamp + 1000
        );
        pair = IPancakePair(factory.getPair(WBNB_ADDRESS, address(token)));

        return pair;
    }

    function swapExactETHForTokens(uint256 amountETH, address tokenAddress)
        public
        returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = WBNB_ADDRESS;
        path[1] = tokenAddress;
        uint256 amountOut = router.swapExactETHForTokens{value: amountETH}(
            0,
            path,
            address(this),
            block.timestamp + 1000
        )[1];
        return amountOut;
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountToken,
        address tokenAddress
    ) public returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = WBNB_ADDRESS;
        uint256 amountETHBefore = address(this).balance;
        IERC20(tokenAddress).approve(address(router), amountToken);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToken,
            0,
            path,
            address(this),
            block.timestamp + 1000
        );
        uint256 amountOut = address(this).balance - amountETHBefore;
        return amountOut;
    }

    receive() external payable {}
}

contract DummyTest is Test {
    function test_Fuck() public {
        emit log_string("fuck!!!");
    }

    function createUser(uint256 amount) public returns (User) {
        User user = new User();
        (bool success, ) = address(user).call{value: amount}("");
        require(success, "send eth error");
        return user;
    }

    function test_DeployToken() public {
        User dev = createUser(2 ether);
        DummyToken devToken = dev.deployToken();

        emit log_named_address("Dev's address", address(dev));
        emit log_named_uint("Dev's balance", address(dev).balance);
        emit log_named_address("Dev Token's address", address(devToken));
        emit log_named_address("Dev Token's owner", devToken.owner());
        emit log_named_uint(
            "Dev Token's balance",
            devToken.balanceOf(address(dev))
        );

        IPancakePair pairToken = dev.addLiquidity(1 ether);
        emit log_named_uint(
            "Dev LP's balance",
            pairToken.balanceOf(address(dev))
        );
        emit log_named_uint("Dev's balance", address(dev).balance);
    }

    function test_BuyAndSellPonziToken() public {
        User dev = createUser(2 ether);
        DummyToken devToken = dev.deployToken();
        dev.addLiquidity(1 ether);

        User user1 = createUser(1 ether);
        User user2 = createUser(1 ether);
        User user3 = createUser(1 ether);

        uint256 tokenGot;
        uint256 ethGot;

        /// @notice user #1 buy token
        emit log_named_uint("user #1 sold this amount of ETH", 0.1 ether);
        tokenGot = user1.swapExactETHForTokens(0.1 ether, address(devToken));
        emit log_named_uint("user #1 got this amount of token", tokenGot);

        /// @notice user #2 buy token
        emit log_named_uint("user #2 sold this amount of ETH", 0.1 ether);
        tokenGot = user2.swapExactETHForTokens(0.1 ether, address(devToken));
        emit log_named_uint("user #2 got this amount of token", tokenGot);
        
        /// @notice user #3 buy token
        emit log_named_uint("user #3 sold this amount of ETH", 0.1 ether);
        tokenGot = user3.swapExactETHForTokens(0.1 ether, address(devToken));
        emit log_named_uint("user #3 got this amount of token", tokenGot);

        /// @notice user #1 sell token
        ethGot = user1.swapExactTokensForETHSupportingFeeOnTransferTokens(
            devToken.balanceOf(address(user1)),
            address(devToken)
        );
        emit log_named_uint("sold all token, user #1 got this amount of ETH", ethGot);
        emit log_named_int("user #1 profit", int(ethGot) - 0.1 ether);
        
        /// @notice user #2 sell token
        ethGot = user2.swapExactTokensForETHSupportingFeeOnTransferTokens(
            devToken.balanceOf(address(user2)),
            address(devToken)
        );
        emit log_named_uint("sold all token, user #2 got this amount of ETH", ethGot);
        emit log_named_int("user #2 profit", int(ethGot) - 0.1 ether);

        /// @notice user #3 sell token
        ethGot = user3.swapExactTokensForETHSupportingFeeOnTransferTokens(
            devToken.balanceOf(address(user3)),
            address(devToken)
        );
        emit log_named_uint("sold all token, user #3 got this amount of ETH", ethGot);
        emit log_named_int("user #3 profit", int(ethGot) - 0.1 ether);

    }
}
