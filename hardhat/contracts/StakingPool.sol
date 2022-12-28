pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

//import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";
import "./interfaces/IDepositContract.sol";
import "./interfaces/IFrensPoolShare.sol";
import "./interfaces/IStakingPool.sol";
import "./FrensBase.sol";


//should ownable be replaces with an equivalent in storage/base?
contract StakingPool is IStakingPool, Ownable, FrensBase {

  event Stake(address depositContractAddress, address caller);
  event DepositToPool(uint amount, address depositer);

  IFrensPoolShare frensPoolShare;

  constructor(address owner_, IFrensStorage frensStorage_) FrensBase(frensStorage_){
    address frensPoolShareAddress = getAddress(keccak256(abi.encodePacked("contract.address", "FrensPoolShare")));
    frensPoolShare = IFrensPoolShare(frensPoolShareAddress); //this hardcodes the nft contract to the pool
    _transferOwnership(owner_);

  }
//TODO: needs to interact with SSVtoken (via amm, check balance, check minimum amount needed in contract etc)
  function depositToPool() public payable {
    require(_getStateHash() == _getStringHash("acceptingDeposits"), "not accepting deposits");
    require(msg.value != 0, "must deposit ether");
    require(getUint(keccak256(abi.encodePacked("total.deposits", address(this)))) + msg.value <= 32 ether, "total depostis cannot be more than 32 Eth");
    addUint(keccak256(abi.encodePacked("token.id")), 1);
    uint id = getUint(keccak256(abi.encodePacked("token.id")));
    setUint(keccak256(abi.encodePacked("deposit.amount", id)), msg.value);
    addUint(keccak256(abi.encodePacked("total.deposits", address(this))), msg.value);
    pushUint(keccak256(abi.encodePacked("ids.in.pool", address(this))), id);
    frensPoolShare.mint(msg.sender, address(this));
    emit DepositToPool(msg.value,  msg.sender);
  }

  function addToDeposit(uint _id) public payable {
    require(frensPoolShare.exists(_id), "id does not exist");
    require(getAddress(keccak256(abi.encodePacked("pool.for.id", _id))) == address(this), "wrong staking pool");
    require(_getStateHash() == _getStringHash("acceptingDeposits"), "not accepting deposits");
    require(getUint(keccak256(abi.encodePacked("total.deposits", address(this)))) + msg.value <= 32 ether, "total depostis cannot be more than 32 Eth");
    addUint(keccak256(abi.encodePacked("deposit.amount", _id)), msg.value);
    addUint(keccak256(abi.encodePacked("total.deposits", address(this))), msg.value);
  }

  function withdraw(uint _id, uint _amount) public {
    require(_getStateHash() != _getStringHash("staked"), "cannot withdraw once staked");//TODO: this may need to be more restrictive
    require(msg.sender == frensPoolShare.ownerOf(_id), "not the owner");
    require(getUint(keccak256(abi.encodePacked("deposit.amount", _id))) >= _amount, "not enough deposited");
    subUint(keccak256(abi.encodePacked("deposit.amount", _id)), _amount);
    subUint(keccak256(abi.encodePacked("total.deposits", address(this))), _amount);
    payable(msg.sender).transfer(_amount);
  }
  //TODO think about other options for distribution
  function distribute() public {
    require(_getStateHash() == _getStringHash("staked"), "use withdraw when not staked");
    uint contractBalance = address(this).balance;
    uint[] memory idsInPool = getIdsInThisPool();
    require(contractBalance > 100, "minimum of 100 wei to distribute");
    for(uint i=0; i<idsInPool.length; i++) {
      uint id = idsInPool[i];
      address tokenOwner = frensPoolShare.ownerOf(id);
      uint share = _getShare(id, contractBalance);
      payable(tokenOwner).transfer(share);
    }
  }

  function getIdsInThisPool() public view returns(uint[] memory) {
    return getArray(keccak256(abi.encodePacked("ids.in.pool", address(this))));
  }

  function _getShare(uint _id, uint _contractBalance) internal view returns(uint) {
    uint depAmt = getUint(keccak256(abi.encodePacked("deposit.amount", _id)));
    uint totDeps = getUint(keccak256(abi.encodePacked("total.deposits", address(this))));
    if(depAmt == 0) return 0;
    uint calcedShare =  _contractBalance * depAmt / totDeps;
    if(calcedShare > 1){
      return(calcedShare - 1); //steal 1 wei to avoid rounding errors drawing balance negative
    }else return 0;
  }

  function getShare(uint _id) public view returns(uint) {
    uint contractBalance = address(this).balance;
    return _getShare(_id, contractBalance);
  }

  function getDistributableShare(uint _id) public view returns(uint) {
    if(_getStateHash() == _getStringHash("acceptingDeposits")) {
      return 0;
    } else {
      return getShare(_id);
    }
  }

  function getPubKey() public view returns(bytes memory){
    return getBytes(keccak256(abi.encodePacked("validator.public.key", address(this))));
  }

  function setPubKey(bytes memory _publicKey) public onlyOwner{
    require(_getStateHash() == _getStringHash("acceptingDeposits"), "wrong state");
    //add checks for ssv operators?
    setBytes(keccak256(abi.encodePacked("validator.public.key", address(this))), _publicKey);
  }

  function getState() public view returns(string memory){
    return getString(keccak256(abi.encodePacked("contract.state", address(this))));
  }

  function _getStateHash() internal view returns(bytes32){
    return keccak256(abi.encodePacked(getState()));
  }

  function _getStringHash(string memory s) internal pure returns(bytes32){
    return keccak256(abi.encodePacked(s));
  }

  function getDepositAmount(uint _id) public view returns(uint){
    return getUint(keccak256(abi.encodePacked("deposit.amount", _id)));
  }

  function getTotalDeposits() public view returns(uint){
    return getUint(keccak256(abi.encodePacked("total.deposits", address(this))));
  }

//should staking info be added to pool before depositing is enabled?
  function stake(
    bytes calldata pubKey,
    bytes calldata withdrawal_credentials,
    bytes calldata signature,
    bytes32 deposit_data_root
  ) public onlyOwner{
    require(address(this).balance >= 32 ether, "not enough eth");
    require(_getStateHash() == _getStringHash("acceptingDeposits"), "wrong state");
    bytes memory zero;
    bytes memory validatorPublicKey = getBytes(keccak256(abi.encodePacked("validator.public.key", address(this))));
    if(keccak256(validatorPublicKey) != keccak256(zero)){
      require(keccak256(validatorPublicKey) == keccak256(pubKey), "pubkey does not match stored value");
    } else setBytes(keccak256(abi.encodePacked("validator.public.key", address(this))), pubKey);
    setString(keccak256(abi.encodePacked("contract.state", address(this))), "staked");
    uint value = 32 ether;
    //get expected withdrawal_credentials based on contract address
    bytes memory withdrawalCredFromAddr = _toWithdrawalCred(address(this));
    //compare expected withdrawal_credentials to provided
    require(keccak256(withdrawal_credentials) == keccak256(withdrawalCredFromAddr), "withdrawal credential mismatch");
    address depositContractAddress = getAddress(keccak256(abi.encodePacked("external.contract.address", "DepositContract")));
    IDepositContract(depositContractAddress).deposit{value: value}(pubKey, withdrawal_credentials, signature, deposit_data_root);
    emit Stake(depositContractAddress, msg.sender);
  }

  function _toWithdrawalCred(address a) private pure returns (bytes memory) {
    uint uintFromAddress = uint256(uint160(a));
    bytes memory withdralDesired = abi.encodePacked(uintFromAddress + 0x0100000000000000000000000000000000000000000000000000000000000000);
    return withdralDesired;
  }

//REMOVE rugpull is for testing only and should not be in the mainnet version
//if this gets deploied on mainnet call 911 or DM @0xWildhare
  function rugpull() public onlyOwner{
    payable(msg.sender).transfer(address(this).balance);
  }
//REMOVE setFrensPoolShare is for testing only and should not be in the mainnet version
  function setFrensPoolShare(address frensPoolShareAddress_) public onlyOwner {
    frensPoolShare = IFrensPoolShare(frensPoolShareAddress_);
  }

  function unstake() public onlyOwner{
    if(address(this).balance > 100){
      distribute();
    }
    setString(keccak256(abi.encodePacked("contract.state", address(this))), "exited");

    //TODO what else needs to be in here (probably a limiting modifier and/or some requires)
    //TODO: is this where we extract fees?
  }


  // to support receiving ETH by default
  receive() external payable {

  }

  fallback() external payable {}
}
