// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IFrensPoolSetter {

    function depositToPool(uint depositAmount) external returns(bool);

    function addToDeposit(uint id, uint amount) external returns(bool);

    function setPubKey(
        bytes calldata pubKey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
        ) external returns(bool);

    function withdraw(uint _id, uint _amount) external returns(bool);

    function distribute(address tokenOwner, uint share) external returns(bool);

    function setArt(address newArtContract) external returns(bool);
}