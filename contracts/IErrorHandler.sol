// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IErrorHandler {
    error MoneySentFailed(address senderAddress, address receiverAddress, uint256 amount);
    error InvalidAddress(address sentAddress, string errorMsg);
}