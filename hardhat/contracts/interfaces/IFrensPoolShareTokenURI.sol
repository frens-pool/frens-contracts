pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

interface IFrensPoolShareTokenURI {
  function tokenURI(uint256 id) external view returns (string memory);
}
