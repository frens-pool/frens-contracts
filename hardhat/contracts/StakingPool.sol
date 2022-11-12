pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

//import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";
import "./interfaces/StakingPoolFactoryInterface.sol";
import "./interfaces/DepositContractInterface.sol";


contract StakingPool is Ownable {

  event Deposit(address depositContractAddress, address caller);

  mapping (uint => uint) public depositAmount;
  uint public totalDeposits;
  uint[] public idsInThisPool;

  enum State { acceptingDeposits, staked, exited }
  State currentState;

  address public depositContractAddress;
  address private rightfulOwner;

  DepositContractInterface depositContract;
  StakingPoolFactoryInterface factoryContract;

  constructor(address depositContractAddress_, address owner_, address factory_) {
    currentState = State.acceptingDeposits;
    depositContractAddress = depositContractAddress_;
    depositContract = DepositContractInterface(depositContractAddress);
    factoryContract = StakingPoolFactoryInterface(factory_);
    rightfulOwner = owner_;
  }

  function getOwner() public view returns(address){
    return rightfulOwner;
  }

  function sendToOwner() public {
    require(owner() != rightfulOwner, "already done");
    _transferOwnership(rightfulOwner);
  }

  function deposit(address userAddress) public payable {
    require(currentState == State.acceptingDeposits);
    require(msg.value != 0, "must deposit ether");
    uint id = factoryContract.incrementTokenId();
    depositAmount[id] = msg.value;
    totalDeposits += msg.value;
    idsInThisPool.push(id);
    factoryContract.mint(userAddress, id, address(this));
  }

  function addToDeposit(uint _id) public payable {
    require(factoryContract.exists(_id), "not exist");
    require(factoryContract.getPoolById(_id) == address(this), "wrong staking pool");
    require(currentState == State.acceptingDeposits);
    depositAmount[_id] += msg.value;
    totalDeposits += msg.value;
  }

  function withdraw(uint _id, uint _amount) public {
    require(currentState != State.staked, "cannot withdraw once staked");
    require(msg.sender == factoryContract.ownerOf(_id), "not the owner");
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
      address tokenOwner = factoryContract.ownerOf(id);
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


  function stake(
    bytes calldata pubkey,
    bytes calldata withdrawal_credentials,
    bytes calldata signature,
    bytes32 deposit_data_root
  ) public onlyOwner{
    require(address(this).balance >= 32 ether, "not enough eth");
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

//rugpull is for testing only and should not be in the mainnet version
  function rugpull() public onlyOwner{
    payable(msg.sender).transfer(address(this).balance);
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
