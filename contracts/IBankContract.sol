// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IBankContract {
    event MoneyAddedToChainByAddress(address indexed senderAddress, uint256 amount);

    event MoneySentToAddress(address indexed senderAddress, address indexed receiverAddress, uint256 amount);

    event FallBackMoneyAddedToChain(address indexed senderAddress, uint256 amount);

    event NewAllocatedAddressForWithdrawal(address indexed allocatedAddress, uint256 timeStamp);

    function transferOwnership(address newOwner) external;

    function transferToAddress(address to, uint256 amountToSend) external;

    function transferAll(address to) external;

    function balanceReceivedByAddress(address from) external view returns (uint256);

    function bankAccountOwner() external view returns (address);

    function syncAllocatedAddress(address allocated) external;
}