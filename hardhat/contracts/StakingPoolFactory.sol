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
    //construct dn
  }

  function create(
    address owner_
  ) public returns(address) {
    StakingPool stakingPool = new StakingPool(owner_, frensStorage);
    setBool(keccak256(abi.encodePacked("pool.exists", address(stakingPool))), true);//do we need both pool.exists and contract.exists?
    setBool(keccak256(abi.encodePacked("contract.exists", address(stakingPool))), true);
    setString(keccak256(abi.encodePacked("contract.state", address(stakingPool))), "acceptingDeposits");
    emit Create(address(stakingPool), msg.sender, owner_);
    return(address(stakingPool));
  }


}
