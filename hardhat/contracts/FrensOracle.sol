pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./FrensBase.sol";
import "./interfaces/IStakingPool.sol";
import "./interfaces/IFrensOracle.sol";

contract FrensOracle is FrensBase, IFrensOracle {

    mapping(bytes => bool) public isExiting;

    constructor(IFrensStorage _frensStorage) FrensBase(_frensStorage){
        version = 0;
    }

    function checkValidatorState(address poolAddress) external returns(bool) {
        bytes memory pubKey = getBytes(keccak256(abi.encodePacked("pubKey", poolAddress)));
        if(isExiting[pubKey]){
            IStakingPool pool = IStakingPool(poolAddress);
            pool.exitPool();
        }
        return isExiting[pubKey];
    }

   function setExiting(bytes memory pubKey, bool _isExiting) external onlyGuardian{
        isExiting[pubKey] = _isExiting;
   }
    
}