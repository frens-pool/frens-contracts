// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./StakingPool.sol";
import "./FrensBase.sol";

contract StakingPoolFactory is FrensBase {

  event Create(
    address indexed contractAddress,
    address creator,
    address owner
  );

  constructor(IFrensStorage _frensStorage) FrensBase(_frensStorage){
    //construct dn
  }

  function create(
    address owner_
  ) public returns(address) {
    StakingPool stakingPool = new StakingPool(owner_, frensStorage);
    setBool(keccak256(abi.encodePacked("pool.exists", address(stakingPool))), true);//do we need both pool.exists and contract.exists?
    setBool(keccak256(abi.encodePacked("contract.exists", address(stakingPool))), true);
    emit Create(address(stakingPool), msg.sender, owner_);
    return(address(stakingPool));
  }

}
