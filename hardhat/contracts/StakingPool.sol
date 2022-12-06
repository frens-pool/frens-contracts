pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";
import "./interfaces/IStakingPoolFactory.sol";
import "./interfaces/IDepositContract.sol";
import "./interfaces/IFrensPoolShare.sol";
import "./FrensBase.sol";


//should ownable be replaces with an equivalent in storage/base?
contract StakingPool is Ownable, FrensBase {

  event Stake(address depositContractAddress, address caller);
  event DepositToPool(uint amount, address depositer);

//move to storage contract
  uint public totalDeposits;
  uint[] public idsInThisPool;//should this stay locally?
  enum State { acceptingDeposits, staked, exited }//should this stay locally? if not, need to think of all possible states: pending, frozen, underReview, exiting, etc. - maybe this gets its own contract?
  State currentState;//should this stay locally?

  bytes public validatorPubKey;
//^^^^

  IFrensPoolShare frensPoolShare;

  constructor(address owner_, IFrensStorage frensStorage_) FrensBase(frensStorage_){
    currentState = State.acceptingDeposits;
    address frensPoolShareAddress = getAddress(keccak256(abi.encodePacked("contract.address", "FrensPoolShare")));
    frensPoolShare = IFrensPoolShare(frensPoolShareAddress);
    _transferOwnership(owner_);

  }
//TODO: need a cap on deposits
  function depositToPool() public payable {
    require(currentState == State.acceptingDeposits, "not accepting deposits");
    require(msg.value != 0, "must deposit ether");
    addUint(keccak256(abi.encodePacked("token.id")), 1);
    uint id = getUint(keccak256(abi.encodePacked("token.id")));
    setUint(keccak256(abi.encodePacked("deposit.amount", id)), msg.value);
    totalDeposits += msg.value;
    idsInThisPool.push(id);//and this
    frensPoolShare.mint(msg.sender, address(this));
    emit DepositToPool(msg.value,  msg.sender);
  }
//TODO: need a cap on deposits
  function addToDeposit(uint _id) public payable {
    require(frensPoolShare.exists(_id), "not exist");
    require(frensPoolShare.getPoolById(_id) == address(this), "wrong staking pool");
    require(currentState == State.acceptingDeposits, "not accepting deposits");
    require(currentState == State.acceptingDeposits);
    addUint(keccak256(abi.encodePacked("deposit.amount", _id)), msg.value);
    totalDeposits += msg.value;
  }

  function withdraw(uint _id, uint _amount) public {
    require(currentState != State.staked, "cannot withdraw once staked");//TODO: this needs to be more restrictive
    require(msg.sender == frensPoolShare.ownerOf(_id), "not the owner");
    require(getUint(keccak256(abi.encodePacked("deposit.amount", _id))) >= _amount, "not enough deposited");
    subUint(keccak256(abi.encodePacked("deposit.amount", _id)), _amount);
    totalDeposits -= _amount;
    payable(msg.sender).transfer(_amount);
  }
  //TODO think about other options for distribution
  function distribute() public {
    require(currentState == State.staked, "use withdraw when not staked");
    uint contractBalance = address(this).balance;
    require(contractBalance > 100, "minimum of 100 wei to distribute");
    for(uint i=0; i<idsInThisPool.length; i++) {
      uint id = idsInThisPool[i];
      address tokenOwner = frensPoolShare.ownerOf(id);
      uint share = _getShare(id, contractBalance);
      payable(tokenOwner).transfer(share);
    }
  }

  function _getShare(uint _id, uint _contractBalance) internal view returns(uint) {
    uint depAmt = getUint(keccak256(abi.encodePacked("deposit.amount", _id)));
    if(depAmt == 0) return 0;
    uint calcedShare =  _contractBalance * depAmt / totalDeposits;
    if(calcedShare > 1){
      return(calcedShare - 1); //steal 1 wei to avoid rounding errors drawing balance negative
    }else return 0;
  }

  function getShare(uint _id) public view returns(uint) {
    uint contractBalance = address(this).balance;
    return _getShare(_id, contractBalance);
  }

  function getDistributableShare(uint _id) public view returns(uint) {
    if(currentState == State.acceptingDeposits) {
      return 0;
    } else {
      return getShare(_id);
    }
  }

  function getPubKey() public view returns(bytes memory){
    return validatorPubKey;
  }

  function setPubKey(bytes memory publicKey) public onlyOwner{
    require(currentState == State.acceptingDeposits, "wrong state");
    validatorPubKey = publicKey;
  }

  function getState() public view returns(string memory){
    if(currentState == State.staked) return "staked";
    if(currentState == State.acceptingDeposits) return "accepting deposits";
    if(currentState == State.exited) return "exited";
    return "state failure"; //should never happen
  }

//this can move to FrensShare
  function getDepositAmount(uint _id) public view returns(uint){
    return getUint(keccak256(abi.encodePacked("deposit.amount", _id)));
  }

  function stake(
    bytes calldata pubkey,
    bytes calldata withdrawal_credentials,
    bytes calldata signature,
    bytes32 deposit_data_root
  ) public onlyOwner{
    require(address(this).balance >= 32 ether, "not enough eth");
    require(currentState == State.acceptingDeposits, "wrong state");
    bytes memory zero;
    if(keccak256(validatorPubKey) != keccak256(zero)){
      require(keccak256(validatorPubKey) == keccak256(pubkey), "pubkey does not match stored value");
    } else validatorPubKey = pubkey;
    currentState = State.staked;
    uint value = 32 ether;
    //get expected withdrawal_credentials based on contract address
    bytes memory withdrawalCredFromAddr = _toWithdrawalCred(address(this));
    //compare expected withdrawal_credentials to provided
    require(keccak256(withdrawal_credentials) == keccak256(withdrawalCredFromAddr), "withdrawal credential mismatch");
    address depositContractAddress = getAddress(keccak256(abi.encodePacked("external.contract.address", "DepositContract")));
    IDepositContract(depositContractAddress).deposit{value: value}(pubkey, withdrawal_credentials, signature, deposit_data_root);
    emit Stake(depositContractAddress, msg.sender);
  }

  function _toWithdrawalCred(address a) private pure returns (bytes memory) {
    uint uintFromAddress = uint256(uint160(a));
    bytes memory withdralDesired = abi.encodePacked(uintFromAddress + 0x0100000000000000000000000000000000000000000000000000000000000000);
    return withdralDesired;
  }

//REMOVE rugpull is for testing only and should not be in the mainnet version
  function rugpull() public onlyOwner{
    payable(msg.sender).transfer(address(this).balance);
  }
//REMOVE setFrensPoolShare is for testing only and should not be in the mainnet version
  function setFrensPoolShare(address frensPoolShareAddress_) public onlyOwner {
    frensPoolShare = IFrensPoolShare(frensPoolShareAddress_);
  }

  function unstake() public onlyOwner{
    distribute();
    currentState = State.exited;
    //TODO what else needs to be in here (probably a limiting modifier and/or some requires)
    //TODO: is this where we extract fees?
  }


  // to support receiving ETH by default
  receive() external payable {
  
  }

  fallback() external payable {}
}
