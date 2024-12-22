// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IPaymentContract {
    function owner() external view returns (address);
}