pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

//import "hardhat/console.sol";
import "./interfaces/IFrensClaim.sol";
import "./FrensBase.sol";

contract FrensClaim is IFrensClaim, FrensBase {

    constructor(IFrensStorage frensStorage_) FrensBase(frensStorage_){
        version = 2;
    }

    function claim(address claimant) public {
        uint amount = getUint(keccak256(abi.encodePacked("claimable.amount", claimant)));
        setUint(keccak256(abi.encodePacked("claimable.amount", claimant)), 0);
        payable(claimant).transfer(amount);
    }

    function claim() override external {
        claim(msg.sender);
    }


    // to support receiving ETH by default
    receive() external payable {}

    fallback() external payable {}
}