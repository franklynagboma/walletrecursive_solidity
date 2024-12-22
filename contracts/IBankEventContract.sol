// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IBankEventContract {

    event MoneyWithdrawToAddress(address indexed senderAddress, address indexed receiverAddress, uint256 amount);

    error MoneyWithdrawFailed(address senderAddress, address receiverAddress, uint256 amount);
}