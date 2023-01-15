pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

//import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";
import "./interfaces/IDepositContract.sol";
import "./interfaces/IFrensPoolShare.sol";
import "./interfaces/IStakingPool.sol";
import "./interfaces/IFrensClaim.sol";
import "./interfaces/IFrensArt.sol";
import "./FrensBase.sol";


//should ownable be replaces with an equivalent in storage/base?
contract StakingPool is IStakingPool, Ownable, FrensBase {

  event Stake(address depositContractAddress, address caller);
  event DepositToPool(uint amount, address depositer);
  event ExecuteTransaction(
            address sender,
            address to,
            uint value,
            bytes data,
            bytes result
        );

  IFrensPoolShare frensPoolShare;

  constructor(address owner_, IFrensStorage frensStorage_) FrensBase(frensStorage_){
    address frensPoolShareAddress = getAddress(keccak256(abi.encodePacked("contract.address", "FrensPoolShare")));
    frensPoolShare = IFrensPoolShare(frensPoolShareAddress); //this hardcodes the nft contract to the pool
    _transferOwnership(owner_);
    version = 1;
  }

  function depositToPool() external payable {
    require(_getStateHash() == _getStringHash("acceptingDeposits"), "not accepting deposits"); //state must be "aceptingDeposits"
    require(msg.value != 0, "must deposit ether"); //cannot generate 0 value nft
    require(getUint(keccak256(abi.encodePacked("total.deposits", address(this)))) + msg.value <= 32 ether, "total deposits cannot be more than 32 Eth"); //limit deposits to 32 eth

    addUint(keccak256(abi.encodePacked("token.id")), 1); //increment token id
    uint id = getUint(keccak256(abi.encodePacked("token.id"))); //retrieve token id
    setUint(keccak256(abi.encodePacked("deposit.amount", id)), msg.value); //assign msg.value to the deposit.amount of token id
    addUint(keccak256(abi.encodePacked("total.deposits", address(this))), msg.value); //increase total.deposits of this pool by msg.value
    pushUint(keccak256(abi.encodePacked("ids.in.pool", address(this))), id); //add id to list of ids in pool
    setAddress(keccak256(abi.encodePacked("pool.for.id", id)), address(this)); //set this as the pool for id
    frensPoolShare.mint(msg.sender); //mint nft
    emit DepositToPool(msg.value,  msg.sender); 
  }

  function addToDeposit(uint _id) external payable {
    require(frensPoolShare.exists(_id), "id does not exist"); //id must exist
    require(getAddress(keccak256(abi.encodePacked("pool.for.id", _id))) == address(this), "wrong staking pool"); //id must be associated with this pool
    require(_getStateHash() == _getStringHash("acceptingDeposits"), "not accepting deposits"); //pool must be "acceptingDeposits"
    require(getUint(keccak256(abi.encodePacked("total.deposits", address(this)))) + msg.value <= 32 ether, "total deposits cannot be more than 32 Eth"); //limit deposits to 32 eth

    addUint(keccak256(abi.encodePacked("deposit.amount", _id)), msg.value); //add msg.value to deposit.amount for id
    addUint(keccak256(abi.encodePacked("total.deposits", address(this))), msg.value); //add msg.value to total.deposits for pool
  }

  function stake(
    bytes calldata pubKey,
    bytes calldata withdrawal_credentials,
    bytes calldata signature,
    bytes32 deposit_data_root
  ) external onlyOwner{
    //if validator info has previously been entered, check that it is the same, then stake
    if(getBool(keccak256(abi.encodePacked("validator.set", address(this))))){
      bytes memory pubKeyFromStorage = getBytes(keccak256(abi.encodePacked("pubKey", address(this)))); 
      require(keccak256(pubKeyFromStorage) == keccak256(pubKey), "pubKey mismatch");
    }else { //if validator info has not previously been enteren, enter it, then stake
      setPubKey(
        pubKey,
        withdrawal_credentials,
        signature,
        deposit_data_root
      );
    }
    stake();
  }

  function stake() public {
    require(address(this).balance >= 32 ether, "not enough eth"); 
    require(_getStateHash() == _getStringHash("acceptingDeposits"), "wrong state");
    uint value = 32 ether;
    bytes memory pubKey = getBytes(keccak256(abi.encodePacked("pubKey", address(this))));
    bytes memory withdrawal_credentials = getBytes(keccak256(abi.encodePacked("withdrawal_credentials", address(this))));
    bytes memory signature = getBytes(keccak256(abi.encodePacked("signature", address(this))));
    bytes32 deposit_data_root = getBytes32(keccak256(abi.encodePacked("deposit_data_root", address(this))));
    address depositContractAddress = getAddress(keccak256(abi.encodePacked("external.contract.address", "DepositContract")));
    setString(keccak256(abi.encodePacked("contract.state", address(this))), "staked");
    IDepositContract(depositContractAddress).deposit{value: value}(pubKey, withdrawal_credentials, signature, deposit_data_root);
    emit Stake(depositContractAddress, msg.sender);
  }

  function setPubKey(
    bytes calldata pubKey,
    bytes calldata withdrawal_credentials,
    bytes calldata signature,
    bytes32 deposit_data_root
  ) public{
    //get expected withdrawal_credentials based on contract address
    bytes memory withdrawalCredFromAddr = _toWithdrawalCred(address(this));
    //compare expected withdrawal_credentials to provided
    require(keccak256(withdrawal_credentials) == keccak256(withdrawalCredFromAddr), "withdrawal credential mismatch");
    if(getBool(keccak256(abi.encodePacked("validator.locked", address(this))))){
      require(_getStateHash() == _getStringHash("awaitingValidatorInfo"), "wrong state");
      assert(!getBool(keccak256(abi.encodePacked("validator.set", address(this))))); //this should never happen
      setString(keccak256(abi.encodePacked("contract.state", address(this))), "acceptingDeposits");
    }
    require(_getStateHash() == _getStringHash("acceptingDeposits"), "wrong state");
    setBytes(keccak256(abi.encodePacked("pubKey", address(this))), pubKey);
    setBytes(keccak256(abi.encodePacked("withdrawal_credentials", address(this))), withdrawal_credentials);
    setBytes(keccak256(abi.encodePacked("signature", address(this))), signature);
    setBytes32(keccak256(abi.encodePacked("deposit_data_root", address(this))), deposit_data_root);
    setBool(keccak256(abi.encodePacked("validator.set", address(this))), true);
  }

  function arbitraryContractCall(
        address payable to,
        uint256 value,
        bytes calldata data
    ) external onlyOwner returns (bytes memory) {
      require(getBool(keccak256(abi.encodePacked("allowed.contract", to))), "contract not allowed");
      (bool success, bytes memory result) = to.call{value: value}(data);
      require(success, "txn failed");
      emit ExecuteTransaction(
          msg.sender,
          to,
          value,
          data,
          result
      );
      return result;
    }

  function withdraw(uint _id, uint _amount) external {
    require(_getStateHash() != _getStringHash("staked"), "cannot withdraw once staked");//TODO: this may need to be more restrictive
    require(msg.sender == frensPoolShare.ownerOf(_id), "not the owner");
    require(getUint(keccak256(abi.encodePacked("deposit.amount", _id))) >= _amount, "not enough deposited");
    subUint(keccak256(abi.encodePacked("deposit.amount", _id)), _amount);
    subUint(keccak256(abi.encodePacked("total.deposits", address(this))), _amount);
    payable(msg.sender).transfer(_amount);
  }

  //TODO: think about other options for distribution
  //TODO: should this include an option to swap for SSV and pay operators?
  //TODO: is this where we extract fes?
  function distribute() public {
    require(_getStateHash() != _getStringHash("acceptingDeposits"), "use withdraw when not staked");
    _distribute();
      }

  function _distribute() internal {
    uint contractBalance = address(this).balance;
    require(contractBalance > 100, "minimum of 100 wei to distribute");
    IFrensClaim frensClaim = IFrensClaim(getAddress(keccak256(abi.encodePacked("contract.address", "FrensClaim"))));
    uint[] memory idsInPool = getIdsInThisPool();
    for(uint i=0; i<idsInPool.length; i++) {
      uint id = idsInPool[i];
      address tokenOwner = frensPoolShare.ownerOf(id);
      uint share = _getShare(id, contractBalance);
      addUint(keccak256(abi.encodePacked("claimable.amount", tokenOwner)), share);
    }
    payable(address(frensClaim)).transfer(contractBalance); //dust -> claim contract instead of pools - the gas to calculate and leave dust in pool >> lifetime expected dust/pool

  }

  function claim() external {
    claim(msg.sender);
  }

  function claim(address claimant) public {
    IFrensClaim frensClaim = IFrensClaim(getAddress(keccak256(abi.encodePacked("contract.address", "FrensClaim"))));
    frensClaim.claim(claimant);
  }

  function distributeAndClaim() external {
    distribute();
    claim(msg.sender);
  }

  function distributeAndClaimAll() external {
    distribute();
    uint[] memory idsInPool = getIdsInThisPool();
    for(uint i=0; i<idsInPool.length; i++) { //this is expensive for large pools
      uint id = idsInPool[i];
      address tokenOwner = frensPoolShare.ownerOf(id);
      claim(tokenOwner);
    }
  }

  function exitPool() external onlyOwner{
    if(address(this).balance > 100){
      _distribute(); 
    }
    setString(keccak256(abi.encodePacked("contract.state", address(this))), "exited");

    //TODO: what else needs to be in here (probably a limiting modifier and/or some requires) maybe add an arbitrary call to an external contract is enabled?
    //TODO: is this where we extract fees?
    
  }

  //getters

  function _getShare(uint _id, uint _contractBalance) internal view returns(uint) {
    uint depAmt = getUint(keccak256(abi.encodePacked("deposit.amount", _id)));
    uint totDeps = getUint(keccak256(abi.encodePacked("total.deposits", address(this))));
    if(depAmt == 0) return 0;
    uint calcedShare =  _contractBalance * depAmt / totDeps;
    if(calcedShare > 1){
      return(calcedShare - 1); //steal 1 wei to avoid rounding errors drawing balance negative
    }else return 0;
  }

  function _getStateHash() internal view returns(bytes32){
    return keccak256(abi.encodePacked(getState()));
  }

  function _getStringHash(string memory s) internal pure returns(bytes32){
    return keccak256(abi.encodePacked(s));
  }

  function getIdsInThisPool() public view returns(uint[] memory) {
    return getArray(keccak256(abi.encodePacked("ids.in.pool", address(this))));
  }

  function getShare(uint _id) public view returns(uint) {
    uint contractBalance = address(this).balance;
    return _getShare(_id, contractBalance);
  }

  function getDistributableShare(uint _id) public view returns(uint) {
    if(_getStateHash() == _getStringHash("acceptingDeposits")) {
      return 0;
    } else {
      return(getShare(_id));
    }
  }

  function getPubKey() public view returns(bytes memory){
    return getBytes(keccak256(abi.encodePacked("validator.public.key", address(this))));
  }

  function getState() public view returns(string memory){
    return getString(keccak256(abi.encodePacked("contract.state", address(this))));
  }

  function getDepositAmount(uint _id) public view returns(uint){
    return getUint(keccak256(abi.encodePacked("deposit.amount", _id)));
  }

  function getTotalDeposits() public view returns(uint){
    return getUint(keccak256(abi.encodePacked("total.deposits", address(this))));
  }

  function owner() public view override(IStakingPool, Ownable) returns (address){
    return super.owner();
  }

  function _toWithdrawalCred(address a) private pure returns (bytes memory) {
    uint uintFromAddress = uint256(uint160(a));
    bytes memory withdralDesired = abi.encodePacked(uintFromAddress + 0x0100000000000000000000000000000000000000000000000000000000000000);
    return withdralDesired;
  }

  //setters

  function setArt(address newArtContract) external onlyOwner { //do we want the owner to be able to change the art on a whim?
    IFrensArt newFrensArt = IFrensArt(newArtContract);
    string memory newArt = newFrensArt.renderTokenById(1);
    require(bytes(newArt).length != 0, "invalid art contract");
    setAddress(keccak256(abi.encodePacked("pool.specific.art.address", address(this))), newArtContract);
  }


//REMOVE rugpull is for testing only and should not be in the mainnet version
//if this gets deploied on mainnet call 911 or DM @0xWildhare
  function rugpull() public onlyOwner{
    payable(msg.sender).transfer(address(this).balance);
  }

  // to support receiving ETH by default
  receive() external payable {}

  fallback() external payable {}
}
