pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./FrensBase.sol";

contract FrensPoolSetter is FrensBase {

    constructor(IFrensStorage _frensStorage) FrensBase(_frensStorage){
        version = 2;
    }

    function depositToPool(uint depositAmount) external onlyStakingPool(msg.sender) returns(bool) {
        addUint(keccak256(abi.encodePacked("token.id")), 1); //increment token id
        uint id = getUint(keccak256(abi.encodePacked("token.id"))); //retrieve token id
        setUint(keccak256(abi.encodePacked("deposit.amount", id)), depositAmount); //assign msg.value to the deposit.amount of token id
        addUint(keccak256(abi.encodePacked("total.deposits", msg.sender)), depositAmount); //increase total.deposits of this pool by msg.value
        pushUint(keccak256(abi.encodePacked("ids.in.pool", msg.sender)), id); //add id to list of ids in pool
        setAddress(keccak256(abi.encodePacked("pool.for.id", id)), msg.sender); //set this as the pool for id
        return true;
    }

    function addToDeposit(uint id, uint amount) external onlyStakingPool(msg.sender) returns(bool) {
        addUint(keccak256(abi.encodePacked("deposit.amount", id)), amount); //add msg.value to deposit.amount for id
        addUint(keccak256(abi.encodePacked("total.deposits", msg.sender)), amount); //add msg.value to total.deposits for pool
        return true;
    }

    function setPubKey(
    bytes calldata pubKey,
    bytes calldata withdrawal_credentials,
    bytes calldata signature,
    bytes32 deposit_data_root
    ) external onlyStakingPool(msg.sender) returns(bool) {
        setBytes(keccak256(abi.encodePacked("pubKey", msg.sender)), pubKey);
        setBytes(keccak256(abi.encodePacked("withdrawal_credentials", msg.sender)), withdrawal_credentials);
        setBytes(keccak256(abi.encodePacked("signature", msg.sender)), signature);
        setBytes32(keccak256(abi.encodePacked("deposit_data_root", msg.sender)), deposit_data_root);
        setBool(keccak256(abi.encodePacked("validator.set", msg.sender)), true);
        return true;
    }

    function withdraw(uint _id, uint _amount) external onlyStakingPool(msg.sender) returns(bool) {
        subUint(keccak256(abi.encodePacked("deposit.amount", _id)), _amount);
        subUint(keccak256(abi.encodePacked("total.deposits", msg.sender)), _amount);
        return true;
    }

    function distribute(address tokenOwner, uint share) external onlyStakingPool(msg.sender) returns(bool) {
        addUint(keccak256(abi.encodePacked("claimable.amount", tokenOwner)), share);
        return true;
    }

    function setArt(address newArtContract) external onlyStakingPool(msg.sender) returns(bool) { 
        setAddress(keccak256(abi.encodePacked("pool.specific.art.address", msg.sender)), newArtContract);
        return true;
    }
}