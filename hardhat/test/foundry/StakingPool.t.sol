// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../contracts/StakingPool.sol";

contract StakingPoolTest is Test {
    StakingPool public stakingPool;

    address payable public depCont = payable(0x000000000000000000000000DE90517C01778AC7);
    address public contOwner = 0x0000000000000000000000000000000001111738;
    address payable public alice = payable(0x00000000000000000000000000000000000A11cE);
    address payable public bob = payable(0x0000000000000000000000000000000000000B0b);

    function setUp() public {
        stakingPool = new StakingPool(depCont, contOwner);

    }

    function testInitialOwner() public {
      address stakingPoolOwner = stakingPool.owner();
      assertEq(stakingPoolOwner, address(this));
    }

    function testSetOwner() public {
      assertTrue(stakingPool.owner() != address(contOwner));
      stakingPool.sendToOwner();
      assertEq(stakingPool.owner(), address(contOwner));
    }

    function testDeposit(uint128 x) public {
      startHoax(alice);
      stakingPool.deposit{value: x}(alice);
      uint id = stakingPool.tokenOfOwnerByIndex(alice, 0);
      assertTrue(id != 0 );
      uint depAmt = stakingPool.depositAmount(id);
      assertEq(x, depAmt);
      uint totDep = stakingPool.totalDeposits();
      assertEq(x, totDep);
    }

    function testAddToDeposit(uint96 x, uint96 y) public {
      startHoax(alice);
      stakingPool.deposit{value: x}(alice);
      uint id = stakingPool.tokenOfOwnerByIndex(alice, 0);
      assertTrue(id != 0 );
      uint depAmt = stakingPool.depositAmount(id);
      assertEq(x, depAmt);
      stakingPool.addToDeposit{value: y}(id);
      uint depAmt2 = stakingPool.depositAmount(id);
      uint tot = uint(x) + uint(y);
      assertEq(tot, depAmt2);
    }

    function testDepositToBob(uint128 x) public {
      startHoax(alice);
      stakingPool.deposit{value: x}(bob);
      uint id = stakingPool.tokenOfOwnerByIndex(bob, 0);
      assertTrue(id != 0 );
      uint depAmt = stakingPool.depositAmount(id);
      assertEq(x, depAmt);
      uint totDep = stakingPool.totalDeposits();
      assertEq(x, totDep);
    }

    function testWithdraw(uint128 x, uint128 y) public {
      if(x >= y){
        startHoax(alice);
        stakingPool.deposit{value: x}(alice);
        uint id = stakingPool.tokenOfOwnerByIndex(alice, 0);
        assertTrue(id != 0 );
        uint depAmt = stakingPool.depositAmount(id);
        assertEq(x, depAmt);
        stakingPool.withdraw(id, y);
        uint depAmt2 = stakingPool.depositAmount(id);
        uint tot = uint(x) - uint(y);
        assertEq(tot, depAmt2);
      }
    }




}
