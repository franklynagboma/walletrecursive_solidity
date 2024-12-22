// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "./IErrorHandler.sol";

abstract contract Ownable is IErrorHandler {

    address private _owner;

    event OwnerShipChangedTo(address indexed oldOwnerAddress, address indexed newOwnerAddress, uint timeStamp);

    constructor (address initialOwner) {
        _checkAddress(initialOwner);
        _transferOwnership(initialOwner);
    } 

    modifier onlyOwner() {
        require(_owner == msg.sender, "You are not the owner, you are not allowed.");
        _;
    }

    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;

        emit OwnerShipChangedTo({oldOwnerAddress: oldOwner, newOwnerAddress: newOwner, timeStamp: block.timestamp});
    }

    function _currentContractOwner() internal view returns (address) {
        return _owner;
    }

    function _checkAddress(address sender) internal virtual pure {
        // if empty address or 0x000 address was sent
        if (sender == address(0)) {
            revert InvalidAddress({sentAddress: sender, errorMsg: "Invalid address."});
        }
    }
}