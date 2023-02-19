pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

interface IFrensClaim {
    
    function distribute(uint[] calldata ids) external payable  returns(bool);

    function getShare(uint _id) external view returns(uint);

    function claim() external;

    function claim(address claimant) external;
}