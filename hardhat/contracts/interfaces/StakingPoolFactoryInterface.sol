pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";

interface StakingPoolFactoryInterface is IERC721Enumerable{
  function incrementTokenId() external returns(uint);

  function mint(address userAddress, uint id, address _pool) external;

  function exists(uint _id) external returns(bool);

  function getPoolById(uint _id) external view returns(address);


}
