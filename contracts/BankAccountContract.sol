// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "./IBankContract.sol";
import "./Ownable.sol";
import "./IErrorHandler.sol";
import "./wallet/IAllocationWallet.sol";

contract BankAccountContract is IBankContract, IErrorHandler, Ownable {

    mapping (address => uint256) private accountBalances; //for history
    mapping (address allocatedAddress => bool) private authorizedAddresses;

    modifier onlyAuthorized(address authorized) {
        require(_currentContractOwner() == msg.sender || authorizedAddresses[authorized], "You are not allowed.");
        _;
    }

    constructor() Ownable(msg.sender) {}

    function transferToAddress(address to, uint256 amountToSend) external onlyAuthorized(to) {
        uint256 amountToSendInEth = amountToSend * 1 ether;
        require(address(this).balance >= amountToSendInEth, "Insufficient balance.");

        _transferMoney(payable (to), amountToSendInEth);
    }

    function transferAll(address to) external onlyOwner {
        uint256 totalBalance = address(this).balance; // balance is in eth
        require(totalBalance > 0, "Insufficient balance.");

        _transferMoney(payable (to), totalBalance);
    }

    function balanceReceivedByAddress(address from) external view returns (uint256) {
        bool isAlonedAddress = from == msg.sender || _currentContractOwner() == msg.sender;
        require(isAlonedAddress, "Cannot view another address balance.");
        return accountBalances[from];
    }

    function syncAllocatedAddress(address allocated) external {
        IAllocationWallet allocationWallet = IAllocationWallet(msg.sender);
        require(allocationWallet.owner() == _currentContractOwner(), "You are not the owner, allocated wallet sync failed.");
        authorizedAddresses[allocated] = true;
        emit NewAllocatedAddressForWithdrawal(allocated, block.timestamp);
    }
    
    function _transferMoney(address payable to, uint256 amountToSendInEth) private {
        (bool isSuccess, ) = to.call{value: amountToSendInEth, gas: 25000000}("");
        if (isSuccess) {
            emit MoneySentToAddress({senderAddress: msg.sender, receiverAddress: to, amount: amountToSendInEth});
        } else {
            revert MoneySentFailed({senderAddress: msg.sender, receiverAddress: to, amount: amountToSendInEth});
        }
    }

    function transferOwnership(address newOwner) external override onlyOwner {
        _checkAddress(newOwner);
        _transferOwnership(newOwner);
    }

    function bankAccountOwner() external view returns (address) {
        return _currentContractOwner();
    }

    receive() external payable { 
        accountBalances[msg.sender] += msg.value;
        emit MoneyAddedToChainByAddress(msg.sender, msg.value);
    }

    fallback() external payable {
        accountBalances[msg.sender] += msg.value;
        emit FallBackMoneyAddedToChain(msg.sender, msg.value);
    }
}