// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./FrensBase.sol";

contract FrensManager is FrensBase {

  constructor(IFrensStorage _frensStorage) FrensBase(_frensStorage) {
    version = 0;
  }
  
  //set name and address
  function setContract(address _contractAddress, string memory _contractName) public onlyGuardian{
    address previousContract = getAddress(keccak256(abi.encodePacked("contract.address", _contractName)));
    requireNotExist(previousContract);
    setAddress(keccak256(abi.encodePacked("contract.address", _contractName)), _contractAddress);
    setString(keccak256(abi.encodePacked("contract.name", _contractAddress)), _contractName);
  }


  function deleteContract(address _contractAddress, string memory _contractName) public onlyGuardian {
    requireNotExist(_contractAddress);
    deleteAddress(keccak256(abi.encodePacked("contract.address", _contractName)));
    deleteString(keccak256(abi.encodePacked("contract.name", _contractAddress)));
    setBool(keccak256(abi.encodePacked("contract.exists", _contractAddress)), false);
  }

  function setExternalContract(address _contractAddress, string memory _contractName) public onlyGuardian {
    setAddress(keccak256(abi.encodePacked("external.contract.address", _contractName)), _contractAddress);
    setString(keccak256(abi.encodePacked("external.contract.name", _contractAddress)), _contractName);
  }

  function allowExternalContract(address _contractAddress) public onlyGuardian {
    setBool(keccak256(abi.encodePacked("allowed.contract", _contractAddress)), true);
  }

  function disAllowExternalContract(address _contractAddress) public onlyGuardian {
    setBool(keccak256(abi.encodePacked("allowed.contract", _contractAddress)), false);
  }

  function requireNotExist(address _addr) public view {
    require(!getBool(keccak256(abi.encodePacked("contract.exists", _addr))), "method not allowed for contracts that write to storage");
  } 

}
