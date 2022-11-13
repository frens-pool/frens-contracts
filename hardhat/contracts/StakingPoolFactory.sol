// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./StakingPool.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract StakingPoolFactory is Ownable{



  StakingPool[] public stakingPools;
  mapping(address => bool) existsStakingPool;


  address depositContractAddress;
  address ssvRegistryAddress;
  address frensPoolShareAddress;

  event Create(
    uint indexed contractId, //do we use this for anything?
    address indexed contractAddress,
    address creator,
    address owner,
    address depositContractAddress
  );

  event Owners(
    address indexed contractAddress,
    address[] owners,
    uint256 indexed signaturesRequired
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
  ) public returns(address, uint) {
    uint id = numberOfStakingPools();

    StakingPool stakingPool = new StakingPool(depositContractAddress, address(this), frensPoolShareAddress);
    stakingPools.push(stakingPool);
    existsStakingPool[address(stakingPool)] = true;
    StakingPool(stakingPool).transferOwnership(owner_);
    emit Create(id, address(stakingPool), msg.sender, owner_, depositContractAddress);
    return(address(stakingPool), id);
  }

  function numberOfStakingPools() public view returns(uint) {
    return stakingPools.length;
  }

  function getStakingPool(uint256 _index) public view returns (
    address stakingPoolAddress,
    uint balance,
    address owner
  ) {
    StakingPool stakingPool = stakingPools[_index];
    return (address(stakingPool), address(stakingPool).balance, stakingPool.owner());
  }

  function doesStakingPoolExist(address _stakingPoolAddress) public view returns(bool){
    return(existsStakingPool[_stakingPoolAddress]);
  }


}
