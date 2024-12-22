// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "remix_tests.sol";

contract PaymentContractTest {

    address private _owner;
    constructor() {
        _owner = msg.sender;
    }

    function owner() external {
        Assert.equal(_owner, msg.sender, "a");
    }
}