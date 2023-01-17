// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

//import "hardhat/console.sol";
import "./StakingPool.sol";
import "./FrensBase.sol";
import "./interfaces/IStakingPoolFactory.sol";

contract StakingPoolFactory is IStakingPoolFactory, FrensBase {

  event Create(
    address indexed contractAddress,
    address creator,
    address owner
  );

  constructor(IFrensStorage _frensStorage) FrensBase(_frensStorage){
    version = 2;
  }

  function create(
    address owner_, 
    bool validatorLocked
    ) public override returns(address) {
    StakingPool stakingPool = new StakingPool(owner_, validatorLocked, frensStorage);
    setBool(keccak256(abi.encodePacked("pool.exists", address(stakingPool))), true);
    setBool(keccak256(abi.encodePacked("validator.locked", address(stakingPool))), validatorLocked);
    emit Create(address(stakingPool), msg.sender, owner_);
    return(address(stakingPool));
  }


}
