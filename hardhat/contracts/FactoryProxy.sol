// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;


import "./FrensBase.sol";

contract FactoryProxy is FrensBase {

    constructor(IFrensStorage _frensStorage) FrensBase(_frensStorage){
        //construct dn
    }

    function _delegate(address implementation) internal {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            // replaced delegatecall with call to be comptible with storageContract permissions
            let result := call(gas(), implementation, 0, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    function _implementation() internal view returns (address) {
        return getAddress(keccak256(abi.encodePacked("contract.address", "StakingPoolFactory")));
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _delegate(_implementation());
    }
}