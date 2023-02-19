pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./FrensBase.sol";

contract FrensPoolSetter is FrensBase {

    constructor(IFrensStorage _frensStorage) FrensBase(_frensStorage){
        version = 0;
    }

    function create(address stakingPool, bool validatorLocked/*, bool frensLocked, uint poolMin, uint poolMax*/) external returns(bool) {
        string memory callingContract = getString(keccak256(abi.encodePacked("contract.name", msg.sender)));
        require(keccak256(abi.encodePacked(callingContract)) == keccak256(abi.encodePacked("StakingPoolFactory")), "only factory can call");
        setBool(keccak256(abi.encodePacked("pool.exists", stakingPool)), true);
        setBool(keccak256(abi.encodePacked("validator.locked", stakingPool)), validatorLocked);
        //setBool(keccak256(abi.encodePacked("frens.locked", stakingPool)), frensLocked);
        //setUint(keccak256(abi.encodePacked("pool.min", stakingPool)), poolMin);
        //setUint(keccak256(abi.encodePacked("pool.max", stakingPool)), poolMax);
        return true;
    }

    function depositToPool(uint depositAmount) external onlyStakingPool(msg.sender) returns(bool) {
        addUint(keccak256(abi.encodePacked("token.id")), 1); //increment token id
        uint id = getUint(keccak256(abi.encodePacked("token.id"))); //retrieve token id
        setUint(keccak256(abi.encodePacked("deposit.amount", msg.sender, id)), depositAmount); //assign msg.value to the deposit.amount of token id
        addUint(keccak256(abi.encodePacked("total.deposits", msg.sender)), depositAmount); //increase total.deposits of this pool by msg.value
        pushUint(keccak256(abi.encodePacked("ids.in.pool", msg.sender)), id); //add id to list of ids in pool
        setAddress(keccak256(abi.encodePacked("pool.for.id", id)), msg.sender); //set this as the pool for id
        bool transferLocked = getBool(keccak256(abi.encodePacked("frens.locked", msg.sender)));
        setBool(keccak256(abi.encodePacked("transfer.locked", id)), transferLocked); //set transfer lock if  pool is locked (use rageQuit if locked)
        return true;
    }

    function addToDeposit(uint id, uint amount) external onlyStakingPool(msg.sender) returns(bool) {
        require(getAddress(keccak256(abi.encodePacked("pool.for.id", id))) == msg.sender, "wrong staking pool"); //id must be associated with this pool
        addUint(keccak256(abi.encodePacked("deposit.amount", msg.sender, id)), amount); //add msg.value to deposit.amount for id
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
        require(getAddress(keccak256(abi.encodePacked("pool.for.id", _id))) == msg.sender, "wrong staking pool");
        subUint(keccak256(abi.encodePacked("deposit.amount", msg.sender, _id)), _amount);
        subUint(keccak256(abi.encodePacked("total.deposits", msg.sender)), _amount);
        return true;
    }

    function setArt(address newArtContract) external onlyStakingPool(msg.sender) returns(bool) { 
        setAddress(keccak256(abi.encodePacked("pool.specific.art.address", msg.sender)), newArtContract);
        return true;
    }

    function rageQuit(uint id, uint price) external onlyStakingPool(msg.sender) returns(bool) {
        setBool(keccak256(abi.encodePacked("rage.quitting", id)), true);
        setUint(keccak256(abi.encodePacked("rage.time", id)), block.timestamp);
        setUint(keccak256(abi.encodePacked("rage.price", id)), price);
        return true;
    }

    function unlockTransfer(uint id) external onlyStakingPool(msg.sender) returns(bool) {
        setBool(keccak256(abi.encodePacked("transfer.locked", id)), false);
        return true;
    }
}