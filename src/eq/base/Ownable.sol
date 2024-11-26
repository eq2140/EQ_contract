// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    address private _creator;
    EnumerableSet.AddressSet private _owners;

    uint256 public requiredSignatures;

    struct Action {
        uint256 signatureCount;
        bool executed;
        mapping(address => bool) signatures;
    }

    mapping(bytes32 => Action) private actions;

    // Events
    event OwnerAdded(address indexed newOwner);
    event OwnerRemoved(address indexed removedOwner);
    event CreatorTransferred(address indexed oldCreator, address indexed newCreator);
    event RequiredSignaturesChanged(uint256 oldRequiredSignatures, uint256 newRequiredSignatures);
    event MultiSigActionExecuted(bytes32 indexed actionId);
    event ActionSigned(bytes32 indexed actionId, address indexed signer);

    constructor() {
        _creator = msg.sender;
        _owners.add(msg.sender);
        requiredSignatures = 1;
    }

    // Returns the current creator (super-admin)
    function creator() public view returns (address) {
        return _creator;
    }

    // Returns the list of owners
    function owners() public view returns (address[] memory) {
        uint256 length = _owners.length();
        address[] memory ownerArray = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            ownerArray[i] = _owners.at(i);
        }
        return ownerArray;
    }

    // Modifier to allow only the creator
    modifier onlyCreator() {
        require(msg.sender == _creator, "Ownable: caller is not the creator");
        _;
    }

    // Modifier to allow only owners and handle multi-signature logic
    modifier onlyOwner() {
        require(_owners.contains(msg.sender), "Ownable: caller is not an owner");

        if (requiredSignatures > 1) {
            // Compute actionId based on function signature and parameters
            bytes32 actionId = keccak256(abi.encode(msg.data));

            Action storage action = actions[actionId];
            require(!action.executed, "Ownable: action already executed");
            require(!action.signatures[msg.sender], "Ownable: action already signed by caller");

            action.signatures[msg.sender] = true;
            action.signatureCount++;

            emit ActionSigned(actionId, msg.sender);

            if (action.signatureCount >= requiredSignatures) {
                action.executed = true;
                emit MultiSigActionExecuted(actionId);
                // Clean up action data to prevent storage growth
                for(uint256 i; i < _owners.length(); i++){
                    delete action.signatures[_owners.at(i)];
                }
                delete actions[actionId];
                _;
            }
            // If not enough signatures, do not execute the function body
        } else {
            _;
        }
    }

    // Public function to add a new owner, only callable by the creator
    function addOwner(address newOwner) public onlyCreator {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        require(!_owners.contains(newOwner), "Ownable: address is already an owner");
        _owners.add(newOwner);
        emit OwnerAdded(newOwner);
    }

    // Public function to remove an owner, only callable by the creator
    function removeOwner(address ownerToRemove) public onlyCreator {
        require(_owners.contains(ownerToRemove), "Ownable: address is not an owner");
        require(ownerToRemove != address(0), "Ownable: cannot remove the zero address");

        _owners.remove(ownerToRemove);
        emit OwnerRemoved(ownerToRemove);
    }

    // Public function to transfer creator role, only callable by the current creator
    function transferCreator(address newCreator) public onlyCreator {
        require(newCreator != address(0), "Ownable: new creator is the zero address");
        emit CreatorTransferred(_creator, newCreator);
        _creator = newCreator;
    }

    // Public function to set required signatures, only callable by the creator
    function setRequiredSignatures(uint256 newRequiredSignatures) public onlyCreator {
        require(newRequiredSignatures > 0, "Ownable: required signatures must be greater than 0");
        require(newRequiredSignatures <= _owners.length(), "Ownable: required signatures exceed owner count");
        uint256 oldRequiredSignatures = requiredSignatures;
        requiredSignatures = newRequiredSignatures;

        emit RequiredSignaturesChanged(oldRequiredSignatures, newRequiredSignatures);
    }
}
