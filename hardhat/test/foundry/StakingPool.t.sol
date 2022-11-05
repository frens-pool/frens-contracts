// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../contracts/StakingPool.sol";

contract StakingPoolTest is Test {
    StakingPool public stakingPool;

    address payable public depCont = payable(0x00000000219ab540356cBB839Cbe05303d7705Fa);
    address public contOwner = 0x0000000000000000000000000000000001111738;
    address payable public alice = payable(0x00000000000000000000000000000000000A11cE);
    address payable public bob = payable(0x0000000000000000000000000000000000000B0b);

    bytes pubkey = hex"94d2bb1aa60d69ff5d26d9f49e0c7380db1a603f7711570bab8a23b8efb4fa1a01711fa4148b88ab0ff3369b735a7b92";
    bytes withdrawal_credentials = hex"010000000000000000000000ce71065d4017f316ec606fe4422e11eb2c47c246";
    bytes signature = hex"b135dc43fa71624d44f3e9e4220dccc95d6586189441524d4517785f5136a42eb07ee4ae687ce245c49d0bba37dcb5960903e5dca37367a5b9ef280c8b041ce2b2d3adc2dad0e73b5462a8030ece563b23fd8b04c1754229e23385f6f1431cd4";
    bytes32 deposit_data_root = 0xbebd5f091f6e2170803a5c5196743b9e37dcab1cce62eb92b6d82b1698677251;

    function setUp() public returns(uint){
        stakingPool = new StakingPool(depCont, contOwner);
        return(address(stakingPool).balance);
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
      if(x > 0){
        startHoax(alice);
        stakingPool.deposit{value: x}(alice);
        uint id = stakingPool.tokenOfOwnerByIndex(alice, 0);
        assertTrue(id != 0 );
        uint depAmt = stakingPool.depositAmount(id);
        assertEq(x, depAmt);
        uint totDep = stakingPool.totalDeposits();
        assertEq(x, totDep);
      }
    }

    function testAddToDeposit(uint96 x, uint96 y) public {
      if(x > 0 && y > 0){
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
    }

    function testDepositToBob(uint128 x) public {
      if(x > 0){
        startHoax(alice);
        stakingPool.deposit{value: x}(bob);
        uint id = stakingPool.tokenOfOwnerByIndex(bob, 0);
        assertTrue(id != 0 );
        uint depAmt = stakingPool.depositAmount(id);
        assertEq(x, depAmt);
        uint totDep = stakingPool.totalDeposits();
        assertEq(x, totDep);
      }
    }

    function testWithdraw(uint128 x, uint128 y) public {
      if(x >= y && x > 0){
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

    function testStake() public {
      stakingPool.sendToOwner();
      uint initialBalance = address(stakingPool).balance; //bc someone sent eth to this address on mainnet.
      hoax(alice);
      stakingPool.deposit{value: 32000000000000000000}(alice);
      assertEq(initialBalance + 32000000000000000000, address(stakingPool).balance);
      hoax(contOwner);
      //for this test to pass, it must be run on a mainnet fork,
      //and the vlaues below must all be correctly gererated in the staking_deposit_cli
      //use: ./deposit new-mnemonic --num_validators 1 --chain mainnet --eth1_withdrawal_address
      //followed by the stakingPool contract address
      stakingPool.stake(pubkey, withdrawal_credentials, signature, deposit_data_root);
      assertEq(initialBalance, address(stakingPool).balance);
    }

    function testDistribute(uint32 x, uint32 y) public {
        if(x != 0 && y > 100){
          uint maxUint32 = 4294967295;
          uint aliceDeposit = uint(x) * 31999999999999999999 / maxUint32;
          uint bobDeposit = 32000000000000000000 - aliceDeposit;
          stakingPool.sendToOwner();
          hoax(alice);
          stakingPool.deposit{value: aliceDeposit}(alice);
          hoax(bob);
          stakingPool.deposit{value: bobDeposit}(bob);
          startHoax(contOwner);
          stakingPool.stake(pubkey, withdrawal_credentials, signature, deposit_data_root);
          uint aliceBalance = address(alice).balance;
          uint bobBalance = address(bob).balance;
          uint aliceShare = (uint(y) + address(stakingPool).balance) * aliceDeposit / 32000000000000000000;
          uint bobShare = (uint(y) + address(stakingPool).balance) - aliceShare;
          payable(stakingPool).transfer(y);
          stakingPool.distribute();
          if(aliceShare == 1) aliceShare = 0;
          if(bobShare == 1) bobShare =0;
          uint aliceBalanceExpected = aliceBalance + aliceShare;
          aliceBalance = address(alice).balance;
          //to account for rounding errors max 2 wei (bc we subtract 1 wei in contract to avoid drawing negative)
          if(aliceBalance != aliceBalanceExpected) aliceBalance += 1;
          if(aliceBalance != aliceBalanceExpected) aliceBalance += 1;
          assertEq(aliceBalance, aliceBalanceExpected);
          uint bobBalanceExpected = bobBalance + bobShare;
          bobBalance = address(bob).balance;
          //to account for rounding errors max 2 wei (bc we subtract 1 wei in contract to avoid drawing negative)
          if(bobBalance != bobBalanceExpected) bobBalance += 1;
          if(bobBalance != bobBalanceExpected) bobBalance += 1;
          assertEq(bobBalance, bobBalanceExpected);

        }

    }

}
