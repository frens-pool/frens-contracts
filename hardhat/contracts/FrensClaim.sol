pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

//import "hardhat/console.sol";
import "./interfaces/IFrensClaim.sol";
import "./interfaces/IFrensPoolShare.sol";
import "./FrensBase.sol";

contract FrensClaim is IFrensClaim, FrensBase {

    IFrensPoolShare frensPoolShare;

    constructor(IFrensStorage frensStorage_) FrensBase(frensStorage_){
        address frensPoolShareAddress = getAddress(keccak256(abi.encodePacked("contract.address", "FrensPoolShare")));
        frensPoolShare = IFrensPoolShare(frensPoolShareAddress); //this hardcodes the nft contract to this contract
        version = 0;
    }

    function distribute(uint[] calldata ids) external payable onlyStakingPool(msg.sender) returns(bool) {
        for(uint i=0; i<ids.length; i++) {
            uint id = ids[i];
            uint share = _getShare(id, msg.value);
            address claimant = frensPoolShare.ownerOf(id);
            addUint(keccak256(abi.encodePacked("claimable.amount", address(this), claimant)), share);
        }
        return true;
    }

    function getShare(uint _id) external view returns(uint) {
        address pool = getAddress(keccak256(abi.encodePacked("pool.for.id", _id)));
        uint contractBalance = pool.balance;
        return _getShare(_id, contractBalance);
    }

    function _getShare(uint _id, uint _contractBalance) internal view returns(uint) {
        address pool = getAddress(keccak256(abi.encodePacked("pool.for.id", _id)));
        uint depAmt = getUint(keccak256(abi.encodePacked("deposit.amount", pool, _id)));
        uint totDeps = getUint(keccak256(abi.encodePacked("total.deposits", pool)));
        if(depAmt == 0) return 0;
            uint calcedShare =  _contractBalance * depAmt / totDeps;
        if(calcedShare > 1){
            return(calcedShare - 1); //steal 1 wei to avoid rounding errors drawing balance negative
        }else return 0;
    }

    function claim(address claimant) override public {
        uint amount = getUint(keccak256(abi.encodePacked("claimable.amount", address(this), claimant)));
        setUint(keccak256(abi.encodePacked("claimable.amount", address(this), claimant)), 0);
        payable(claimant).transfer(amount);
    }

    function claim() override external {
        claim(msg.sender);
    }

    // to support receiving ETH by default
    receive() external payable {}

    fallback() external payable {}
}