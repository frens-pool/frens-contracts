// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

//import "hardhat/console.sol";
import "./FrensBase.sol";
import "./interfaces/IFrensPoolShareTokenURI.sol";
import "./interfaces/IFrensArt.sol";
import "./interfaces/IFrensPoolShare.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


//should ownable be replaces with an equivalent in storage/base? (needs to interface with opensea properly)
contract FrensPoolShare is IFrensPoolShare, ERC721Enumerable, Ownable, FrensBase {

  constructor(IFrensStorage _frensStorage) FrensBase(_frensStorage) ERC721("staking con amigos", "FRENS") {
    //hi fren
  }

  function mint(address userAddress, address _pool) public onlyStakingPool(msg.sender) {
    uint id = getUint(keccak256(abi.encodePacked("token.id")));
    setAddress(keccak256(abi.encodePacked("pool.for.id", id)), _pool);
    _safeMint(userAddress, id);
  }

  function exists(uint _id) public view returns(bool){
    return _exists(_id);
  }

  //does frontend use this? otherwise it can be deleted
  function getPoolById(uint _id) public view returns(address){
    return getAddress(keccak256(abi.encodePacked("pool.for.id", _id)));
  }

  function tokenURI(uint256 id) public view override(ERC721, IFrensPoolShare) returns (string memory) {
    IFrensPoolShareTokenURI _tokenURI = IFrensPoolShareTokenURI(getAddress(keccak256(abi.encodePacked("contract.address", "FrensPoolShareTokenURI"))));
    return _tokenURI.tokenURI(id);
  }

  function renderTokenById(uint256 id) public view returns (string memory){
    IFrensArt frensArt = IFrensArt(getAddress(keccak256(abi.encodePacked("contract.address", "FrensArt"))));
    return frensArt.renderTokenById(id);
  }

}
