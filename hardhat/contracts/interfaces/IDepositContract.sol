
pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT


interface IDepositContract {

    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable;

}
