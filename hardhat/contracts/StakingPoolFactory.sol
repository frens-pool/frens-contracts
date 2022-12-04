// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./StakingPool.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract StakingPoolFactory is Ownable{

  mapping(address => bool) existsStakingPool;

  //this is used for testing may be removed for deployment
  address public lastContract;

  address depositContractAddress;
  address ssvRegistryAddress;
  address frensPoolShareAddress;

  event Create(
    address indexed contractAddress,
    address creator,
    address owner,
    address depositContractAddress
  );

  constructor(address depContAddress_, address ssvRegistryAddress_) {
    depositContractAddress = depContAddress_;
    ssvRegistryAddress = ssvRegistryAddress_;
  }
  function setFrensPoolShare(address frensPoolShareAddress_) public onlyOwner {
    frensPoolShareAddress = frensPoolShareAddress_;
  }

  function create(
    address owner_
  ) public returns(address) {
    StakingPool stakingPool = new StakingPool(depositContractAddress, address(this), frensPoolShareAddress, owner_);
    existsStakingPool[address(stakingPool)] = true;
    lastContract = address(stakingPool); //used for testing can be removed
    emit Create(address(stakingPool), msg.sender, owner_, depositContractAddress);
    return(address(stakingPool));
  }

  function doesStakingPoolExist(address _stakingPoolAddress) public view returns(bool){
    return(existsStakingPool[_stakingPoolAddress]);
  }

}
