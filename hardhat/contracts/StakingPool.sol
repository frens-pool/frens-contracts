pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

//import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";
import "./interfaces/IStakingPoolFactory.sol";
import "./interfaces/IDepositContract.sol";
import "./interfaces/IFrensPoolShare.sol";


contract StakingPool is Ownable {

  event Deposit(address depositContractAddress, address caller);

  mapping (uint => uint) public depositAmount;
  uint public totalDeposits;
  uint[] public idsInThisPool;

  enum State { acceptingDeposits, staked, exited }
  State currentState;

  address public depositContractAddress;
  address private rightfulOwner;
  bytes public validatorPubKey;

  IDepositContract depositContract;
  IStakingPoolFactory factoryContract;
  IFrensPoolShare frensPoolShare;

  constructor(address depositContractAddress_, address factory_, address frensPoolShareAddress_) {
    currentState = State.acceptingDeposits;
    depositContractAddress = depositContractAddress_;
    depositContract = IDepositContract(depositContractAddress);
    factoryContract = IStakingPoolFactory(factory_);
    frensPoolShare = IFrensPoolShare(frensPoolShareAddress_);

  }

  function deposit(address userAddress) public payable {
    require(currentState == State.acceptingDeposits, "not accepting deposits");
    require(msg.value != 0, "must deposit ether");
    uint id = frensPoolShare.incrementTokenId();
    depositAmount[id] = msg.value;
    totalDeposits += msg.value;
    idsInThisPool.push(id);
    frensPoolShare.mint(userAddress, id, address(this));
  }

  function addToDeposit(uint _id) public payable {
    require(frensPoolShare.exists(_id), "not exist");
    require(frensPoolShare.getPoolById(_id) == address(this), "wrong staking pool");
    require(currentState == State.acceptingDeposits, "not accepting deposits");
    require(currentState == State.acceptingDeposits);
    depositAmount[_id] += msg.value;
    totalDeposits += msg.value;
  }

  function withdraw(uint _id, uint _amount) public {
    require(currentState != State.staked, "cannot withdraw once staked");
    require(msg.sender == frensPoolShare.ownerOf(_id), "not the owner");
    require(depositAmount[_id] >= _amount, "not enough deposited");
    depositAmount[_id] -= _amount;
    totalDeposits -= _amount;
    payable(msg.sender).transfer(_amount);
  }

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
    if(depositAmount[_id] == 0) return 0;
    uint calcedShare =  _contractBalance * depositAmount[_id] / totalDeposits;
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
    validatorPubKey = publicKey;
  }

  function getState() public view returns(string memory){
    if(currentState == State.staked) return "staked";
    if(currentState == State.acceptingDeposits) return "accepting deposits";
    if(currentState == State.exited) return "exited";
    return "state failure"; //should never happen
  }

  function getDepositAmount(uint _id) public view returns(uint){
    return depositAmount[_id];
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
    depositContract.deposit{value: value}(pubkey, withdrawal_credentials, signature, deposit_data_root);
    emit Deposit(depositContractAddress, msg.sender);
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

  function unstake() public {
    distribute();
    currentState = State.exited;
    //TODO what else needs to be in here (probably a limiting modifier and/or some requires)
  }


  // to support receiving ETH by default
  receive() external payable {
    /*
    _tokenId++;
    uint256 id = _tokenId;
    depositAmount[id] = msg.value;
    _mint(msg.sender, id);
    */
  }

  fallback() external payable {}
}
