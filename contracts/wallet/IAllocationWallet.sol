// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IAllocationWallet {
    function viewWalletAddedWithAllocation(address walletAddress) external view returns (bool, uint256);
    function withdrawFromBankContractTo(uint256 amount) external;
    function owner() external view returns (address);
}