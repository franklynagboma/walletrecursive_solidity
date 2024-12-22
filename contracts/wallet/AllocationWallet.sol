// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "./IAllocationWallet.sol";
import "../Ownable.sol";
import "../IBankContract.sol";
import "./IPaymentContract.sol";

contract AllocationWallet is Ownable, IAllocationWallet {

    struct WalletAddressData {
        mapping (address => uint256 allocatedAmount) allocateAmountByAddresses;
        mapping (address => bool isAddedd) isWalletAddressesAdded;
        uint256 totalAllocatedBalance;  
    }
    WalletAddressData private walletData;

    IBankContract private bankContract;

    mapping (address => uint256) private _addressAmountSentToContract;
    uint256 constant private feePenalty = 5;

    event NewAddressAddedToWallet(address indexed newAddress);
    event AmountAllocatedToWallet(address indexed allocatedAddress, uint256 amount);
    event MoneyWithdrawToAddress(address indexed senderAddress, address indexed receiverAddress, uint256 amount);

    error MoneyWithdrawFailed(address senderAddress, address receiverAddress, uint256 amount);
    
    modifier onlyBankContractOwner(address bankContractAddress) {
        _bankContractInterface(bankContractAddress);
        require(bankContract.bankAccountOwner() == msg.sender, "Denied, you are not the owner of the provided bank contract.");
        _;
    }

    constructor(address bankContractAddress) Ownable(msg.sender) onlyBankContractOwner(bankContractAddress) {
        _bankContractInterface(bankContractAddress);
    }

    // If contract ever have some amount sent to it, have the posibility to withdraw all
    function transferAmountProvidedByAddressToAddress() external {
        uint256 amount = _addressAmountSentToContract[msg.sender];
        require(amount > 0, "Address never sent money to this contract.");

        address thisContract = address(this);
        require(thisContract.balance >= amount);

        // Remove 10% for changes send to contract owner
        uint256 tenPercOffAmount = (amount * feePenalty) / 100;
        uint256 balance = thisContract.balance - tenPercOffAmount;

        (bool isTenPercPaymentSuccess, ) = payable (_currentContractOwner()).call{value: tenPercOffAmount, gas: 2500000}("");
        if (!isTenPercPaymentSuccess) {
            revert MoneySentFailed({senderAddress: thisContract, receiverAddress: _currentContractOwner(), amount: tenPercOffAmount});
        }
        
        (bool isSuccess, ) = payable (msg.sender).call{value: balance, gas: 2500000}("");
        if (!isSuccess) {
            revert MoneySentFailed({senderAddress: thisContract, receiverAddress: msg.sender, amount: balance});
        }
        _addressAmountSentToContract[msg.sender] = 0;
    }

    function allocateAmountToWalletAddress(address walletAddress, uint256 amount) external onlyBankContractOwner(address(bankContract)) {
        _addNewAddress(walletAddress);

        require(walletData.isWalletAddressesAdded[walletAddress], "Address not in wallet, add address to wallet.");
        require(amount > 0, "Invalid amount.");

        uint256 amountInEther = amount * 1 ether;
        require(_checkIfBankBalanceIsSufficient(amountInEther), "Insufficient balance in bank account.");

        walletData.allocateAmountByAddresses[walletAddress] += amountInEther;
        walletData.totalAllocatedBalance += amountInEther;
        emit AmountAllocatedToWallet({allocatedAddress: walletAddress, amount: amountInEther});
        
        bankContract.syncAllocatedAddress(walletAddress);
    }

    function viewWalletAddedWithAllocation(address walletAddress) external view returns (bool, uint256) {
        return (_walletHasAddress(walletAddress), _viewWalletAllocation(walletAddress));
    }

    function withdrawFromBankContractTo(uint256 amount) external {
        address to = _validateMsgSenderAsWalletOrPaymentContract(msg.sender);
        require(_walletHasAddress(to), "Not eligible, you are not part of the allocated address.");

        uint256 allocatedAmount = _viewWalletAllocation(to);
        uint256 amountInEther = amount * 1 ether;
        require(allocatedAmount >= amountInEther, "Insufficient allocation, try reduce your withdrawal amount.");

        bankContract.transferToAddress(to, amount);
        walletData.allocateAmountByAddresses[to] -= amountInEther;
        walletData.totalAllocatedBalance -= amountInEther;
    }

    function owner() external view returns (address) {
        return _currentContractOwner();
    }

    function _bankContractInterface(address bankContractAddress) private {
        require(bankContractAddress != address(0));
        if (address(bankContract) == address(0)) {
            bankContract = IBankContract(bankContractAddress);
        }
    }

    function _walletHasAddress(address walletAddress) private view returns (bool) {
        return walletData.isWalletAddressesAdded[walletAddress];
    }

    function _viewWalletAllocation(address walletAddress) private view returns (uint256) {
        address senderAddress = _validateMsgSenderAsWalletOrPaymentContract(msg.sender);
        bool isAlowedAddress = walletAddress == senderAddress || bankContract.bankAccountOwner() == msg.sender;
        require(isAlowedAddress, "You are not allowed to view address allocation");

        return walletData.allocateAmountByAddresses[walletAddress];
    }

    function _checkIfBankBalanceIsSufficient(uint256 amountInEther) private view returns (bool) {
        return address(bankContract).balance >= (walletData.totalAllocatedBalance + amountInEther);
    }

    function _addNewAddress(address newAddress) private {
        if (newAddress == address(0)) {
            revert InvalidAddress({sentAddress: newAddress, errorMsg: "Invalid address."});
        } else {
            walletData.isWalletAddressesAdded[newAddress] = true;
            emit NewAddressAddedToWallet(newAddress);
        }
    }

    function _validateMsgSenderAsWalletOrPaymentContract(address sender) private view returns (address) {
        address walletOrContract;
        if (_currentContractOwner() == sender) {
            walletOrContract = sender;
        } else {
            walletOrContract = _paymentContractOwner(sender);
        }
        return walletOrContract;
    }

    function _paymentContractOwner(address contractAddress) internal view returns (address) {
        //Only the right contract deploy will initiate IPaymentContract successfully.
        IPaymentContract paymentContract = IPaymentContract(contractAddress);
        return paymentContract.owner();
    }

    receive() external payable { 
        _addressAmountSentToContract[msg.sender] += msg.value;
    }

    // function _getOwnerOfBankContract(address bankContractAddress) private returns (address) {
    //     bytes memory payload = abi.encodeWithSignature("bankAccountOwner()");
    //     (bool isSuccess, bytes memory resultData) = bankContractAddress.call(payload);

    //     require(isSuccess, "Bank owner contract call failed.");

    //     address ownerAddress = abi.decode(resultData, (address));
    //     return ownerAddress;
    // }
}