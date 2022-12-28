// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

//Frens Contracts
import "../../contracts/FrensArt.sol";
import "../../contracts/FrensInitialiser.sol";
import "../../contracts/FrensMetaHelper.sol";
import "../../contracts/FrensPoolShareTokenURI.sol";
import "../../contracts/FrensStorage.sol";
import "../../contracts/FactoryProxy.sol";
import "../../contracts/StakingPool.sol";
import "../../contracts/StakingPoolFactory.sol";
import "../../contracts/FrensPoolShare.sol";
import "../../contracts/interfaces/IStakingPoolFactory.sol";

contract StakingPoolTest is Test {
    FrensArt public frensArt;
    FrensInitialiser public frensInitialiser;
    FrensMetaHelper public frensMetaHelper;
    FrensPoolShareTokenURI public frensPoolShareTokenURI;
    FrensStorage public frensStorage;
    FactoryProxy public factoryProxy;
    StakingPoolFactory public stakingPoolFactory;
    StakingPool public stakingPool;
    FrensPoolShare public frensPoolShare;
    IStakingPoolFactory public proxy;

    //mainnet
    address payable public depCont = payable(0x00000000219ab540356cBB839Cbe05303d7705Fa);
    //goerli
    //address payable public depCont = payable(0xff50ed3d0ec03aC01D4C79aAd74928BFF48a7b2b);
    address public ssvRegistryAddress = 0xb9e155e65B5c4D66df28Da8E9a0957f06F11Bc04;
    address public contOwner = 0x0000000000000000000000000000000001111738;
    address payable public alice = payable(0x00000000000000000000000000000000000A11cE);
    address payable public bob = payable(0x0000000000000000000000000000000000000B0b);

    bytes pubkey = hex"85ce659c43b0d710380a13eac8de4d8f1a4dd1ab615e25d0004ca75762582b1f1bc2a11972fde4f7690ff84c7d9d50e1";
    bytes withdrawal_credentials = hex"010000000000000000000000037fc82298142374d974839236d2e2df6b5bdd8f";
    bytes signature = hex"90f429cffe3ccb7147de60265de01e48007432ce5f3b79798fc8fdf2c582aaec0fee7e5ce4d28d7f43c367a7fc57c86b1640842ab97de6ae68ba4581c411eeccef79057857fd74ebaf3be3e307a91be8008d8865c65ab57ef6b3d6872ea350ad";
    bytes32 deposit_data_root = 0xb60b0cd349fe1048322cd8fe3d35d10e7f937837da3a2afaf0433444da1d8618;

    function setUp() public {
      //deploy storage
      frensStorage = new FrensStorage();
      //deploy proxy
      factoryProxy = new FactoryProxy(frensStorage);
      //connect proxy with factory interface
      proxy = IStakingPoolFactory(address(factoryProxy));
      //deploy initialiser
      frensInitialiser = new FrensInitialiser(frensStorage);
      //initialise initialiser
      //tx.origin must be this contract
      vm.prank(address(this), address(this));
      frensInitialiser.setContract(address(frensInitialiser), "FrensInitialiser");
      //initialise SSVRegistry
      frensInitialiser.setExternalContract(ssvRegistryAddress, "SSVRegistry");
      //initialise deposit Contract
      frensInitialiser.setExternalContract(depCont, "DepositContract");
      //deploy NFT contract
      frensPoolShare = new FrensPoolShare(frensStorage);
      //initialise NFT contract
      frensInitialiser.setContract(address(frensPoolShare), "FrensPoolShare");
      //deploy Factory
      stakingPoolFactory = new StakingPoolFactory(frensStorage);
      //initialise Factory
      frensInitialiser.setContract(address(stakingPoolFactory), "StakingPoolFactory");
      //deploy MetaHelper
      frensMetaHelper = new FrensMetaHelper(frensStorage);
      //initialise Metahelper
      frensInitialiser.setContract(address(frensMetaHelper), "FrensMetaHelper");
      //deploy TokenURI
      frensPoolShareTokenURI = new FrensPoolShareTokenURI(frensStorage);
      //Initialise TokenURI
      frensInitialiser.setContract(address(frensPoolShareTokenURI), "FrensPoolShareTokenURI");
      //deployArt
      frensArt = new FrensArt(frensStorage);
      //initialise art
      frensInitialiser.setContract(address(frensArt), "FrensArt");

      //create staking pool through proxy contract
      (address pool) = proxy.create(contOwner);
      //connect to staking pool
      stakingPool = StakingPool(payable(pool));
      //console.log the pool address for fun  if(FrensPoolShareOld == 0){
      console.log("pool", pool);
    }

    function testOwner() public {
      address stakingPoolOwner = stakingPool.owner();
      assertEq(stakingPoolOwner, address(contOwner));
    }

/* all tests were written for previous version of the contracts and must be updated
    

    function testDeposit(uint128 x) public {
      if(x > 0){
        startHoax(alice);
        stakingPool.depositToPool{value: x}();
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
        stakingPool.depositToPool{value: x}();
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

    function testWithdraw(uint128 x, uint128 y) public {
      if(x >= y && x > 0){
        startHoax(alice);
        stakingPool.depositToPool{value: x}();
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
      stakingPool.depositToPool{value: 32000000000000000000}();
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
          stakingPool.depositToPool{value: aliceDeposit}();
          hoax(bob);
          stakingPool.depositToPool{value: bobDeposit}();
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
*/

}
