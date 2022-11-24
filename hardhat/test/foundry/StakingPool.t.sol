// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../contracts/StakingPool.sol";
import "../../contracts/StakingPoolFactory.sol";
import "../../contracts/FrensPoolShare.sol";

contract StakingPoolTest is Test {
    StakingPoolFactory public stakingPoolFactory;
    StakingPool public stakingPool;
    FrensPoolShare public frensPoolShare;

    address payable public depCont = payable(0x00000000219ab540356cBB839Cbe05303d7705Fa);
    address public ssvRegistryAddress = 0xb9e155e65B5c4D66df28Da8E9a0957f06F11Bc04;
    address public contOwner = 0x0000000000000000000000000000000001111738;
    address payable public alice = payable(0x00000000000000000000000000000000000A11cE);
    address payable public bob = payable(0x0000000000000000000000000000000000000B0b);

    bytes pubkey = hex"85ce659c43b0d710380a13eac8de4d8f1a4dd1ab615e25d0004ca75762582b1f1bc2a11972fde4f7690ff84c7d9d50e1";
    bytes withdrawal_credentials = hex"010000000000000000000000037fc82298142374d974839236d2e2df6b5bdd8f";
    bytes signature = hex"90f429cffe3ccb7147de60265de01e48007432ce5f3b79798fc8fdf2c582aaec0fee7e5ce4d28d7f43c367a7fc57c86b1640842ab97de6ae68ba4581c411eeccef79057857fd74ebaf3be3e307a91be8008d8865c65ab57ef6b3d6872ea350ad";
    bytes32 deposit_data_root = 0xb60b0cd349fe1048322cd8fe3d35d10e7f937837da3a2afaf0433444da1d8618;

    function setUp() public {
      stakingPoolFactory = new StakingPoolFactory(depCont, ssvRegistryAddress);
      frensPoolShare = new FrensPoolShare(address(stakingPoolFactory), ssvRegistryAddress);
      stakingPoolFactory.setFrensPoolShare(address(frensPoolShare));
      (address pool,) = stakingPoolFactory.create(contOwner);

      stakingPool = StakingPool(payable(pool));

    }

    function testOwner() public {
      address stakingPoolOwner = stakingPool.owner();
      assertEq(stakingPoolOwner, address(contOwner));
    }
    /* since deploying through factory contract, this is already done.
    function testSetOwner() public {
      assertTrue(stakingPool.owner() != address(contOwner));
      stakingPool.sendToOwner();
      assertEq(stakingPool.owner(), address(contOwner));
    }
    */
    function testDeposit(uint128 x) public {
      if(x > 0){
        startHoax(alice);
        stakingPool.deposit{value: x}(alice);
        uint id = frensPoolShare.tokenOfOwnerByIndex(alice, 0);
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
        uint id = frensPoolShare.tokenOfOwnerByIndex(alice, 0);
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
        uint id = frensPoolShare.tokenOfOwnerByIndex(bob, 0);
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
        uint id = frensPoolShare.tokenOfOwnerByIndex(alice, 0);
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
      //stakingPool.sendToOwner();
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
          //stakingPool.sendToOwner();
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
