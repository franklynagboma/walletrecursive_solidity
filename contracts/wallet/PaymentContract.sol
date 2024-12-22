// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "./IAllocationWallet.sol";
import "./IPaymentContract.sol";
import "../Ownable.sol";
import "../IErrorHandler.sol";

contract PaymentContract is IPaymentContract, IErrorHandler, Ownable {

    IAllocationWallet private allocationWallet;
    address payable private bankContract;
    mapping (address => uint256) private _addressAmountSentToContract;

    constructor() Ownable(msg.sender){}

    function setAllocationContract(address allocationWalletContractAddress) external {
        allocationWallet = IAllocationWallet(allocationWalletContractAddress);
    }

    function viewAddressAllocation() external view returns (bool, uint256) {
        _checkAddress(address(allocationWallet));
        return allocationWallet.viewWalletAddedWithAllocation(msg.sender);
    }

    function withdrawMoney(uint256 amount) external {
        _checkAddress(address(allocationWallet));
        allocationWallet.withdrawFromBankContractTo(amount);
    }

    function owner() external view returns (address) {
        return _currentContractOwner();
    }

    // If contract ever have some amount sent to it, have the posibility to withdraw all
    function transferAmountProvidedByAddressToAddress() external {
        uint256 amount = _addressAmountSentToContract[msg.sender];
        require(amount > 0, "Address never sent money to this contract.");
        address thisContract = address(this);
        require(thisContract.balance >= amount);
        (bool isSuccess, ) = payable (msg.sender).call{value: amount, gas: 2500000}("");
        if (!isSuccess) {
            revert MoneySentFailed({senderAddress: thisContract, receiverAddress: msg.sender, amount: amount});
        }
    }

    function _checkAddress(address sender) internal override  pure {
        // if empty address or 0x000 address was sent
        if (sender == address(0)) {
            revert InvalidAddress({sentAddress: sender, errorMsg: "Invalid allocation contract address provided."});
        }
    }

    receive() external payable { 
        _addressAmountSentToContract[msg.sender] += msg.value;
    }
}