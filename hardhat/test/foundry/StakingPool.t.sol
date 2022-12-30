// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/*
 test command:
 forge test --via-ir --fork-url https://mainnet.infura.io/v3/7b367f3e8f1d48e5b43e1b290a1fde16
*/

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
import "../../contracts/interfaces/IDepositContract.sol";

contract StakingPoolTest is Test {
    FrensArt public frensArt;
    FrensInitialiser public frensInitialiser;
    FrensMetaHelper public frensMetaHelper;
    FrensPoolShareTokenURI public frensPoolShareTokenURI;
    FrensStorage public frensStorage;
    FactoryProxy public factoryProxy;
    StakingPoolFactory public stakingPoolFactory;
    StakingPool public stakingPool;
    StakingPool public stakingPool2;
    FrensPoolShare public frensPoolShare;
    IStakingPoolFactory public proxy;

    //mainnet
    address payable public depCont = payable(0x00000000219ab540356cBB839Cbe05303d7705Fa);
    //goerli
    //address payable public depCont = payable(0xff50ed3d0ec03aC01D4C79aAd74928BFF48a7b2b);
    address public ssvRegistryAddress = 0xb9e155e65B5c4D66df28Da8E9a0957f06F11Bc04;
    address public ENSAddress = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;

    IDepositContract depositContract = IDepositContract(depCont);

    address public contOwner = 0x0000000000000000000000000000000001111738;
    address payable public alice = payable(0x00000000000000000000000000000000000A11cE);
    address payable public bob = payable(0x0000000000000000000000000000000000000B0b);

    bytes pubkey = hex"b01569ec66772826955cb5ff0637ba938c4be3b01fe1ada49ef7a7ab4b799d259d952488240ca8db87d8a9ebad3a8aa7";
    bytes withdrawal_credentials = hex"010000000000000000000000a38d17ef017a314ccd72b8f199c0e108ef7ca04c";
    bytes signature = hex"b257af61464f370cf607a57b4b124b24f3513591c7c47643542fc655ca655afabd984f81d66b11f607f912162dcbf16d106d30d4ba9bbad0bf8bdd6aaa96d02784843a1116f5b707c7fd15124769279de944dfe2d39411f1a04bb834c0b0bbc3";
    bytes32 deposit_data_root = 0x4362a08597a16707b4f9cde88aa2e9d51d17775b67490726072ce8897128d4c2;

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
      //initialise ENS 
      frensInitialiser.setExternalContract(ENSAddress, "ENS");
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
      (address pool) = proxy.create(contOwner, false);
      //connect to staking pool
      stakingPool = StakingPool(payable(pool));
      //console.log the pool address for fun  if(FrensPoolShareOld == 0){
      console.log("pool", pool);

      //create a second staking pool through proxy contract
      (address pool2) = proxy.create(contOwner, false);
      //connect to staking pool
      stakingPool2 = StakingPool(payable(pool2));
      //console.log the pool address for fun  if(FrensPoolShareOld == 0){
      console.log("pool2", pool2);

    }

    function testOwner() public {
      address stakingPoolOwner = stakingPool.owner();
      assertEq(stakingPoolOwner, address(contOwner));
    }

    function testDeposit(uint72 x) public {
      if(x > 0 && x <= 32 ether){
        startHoax(alice);
        stakingPool.depositToPool{value: x}();
        uint id = frensPoolShare.tokenOfOwnerByIndex(alice, 0);
        assertTrue(id != 0 );
        uint depAmt = stakingPool.getDepositAmount(id);
        assertEq(x, depAmt);
        uint totDep = stakingPool.getTotalDeposits();
        assertEq(x, totDep);
      } else if(x == 0) {
        vm.expectRevert("must deposit ether");
        startHoax(alice);
        stakingPool.depositToPool{value: x}();
      } else {
        vm.expectRevert("total deposits cannot be more than 32 Eth");
        startHoax(alice);
        stakingPool.depositToPool{value: x}();
      }
    }

    function testAddToDeposit(uint64 x, uint64 y) public {
      if(x > 0 && uint(x) + uint(y) <= 32 ether){
        startHoax(alice);
        stakingPool.depositToPool{value: x}();
        uint id = frensPoolShare.tokenOfOwnerByIndex(alice, 0);
        assertTrue(id != 0 );
        uint depAmt = stakingPool.getDepositAmount(id);
        assertEq(x, depAmt);
        //should throw for non-existant id
        vm.expectRevert("id does not exist");
        stakingPool.addToDeposit{value: y}(0);
        //existing id should work fine
        stakingPool.addToDeposit{value: y}(id);
        uint depAmt2 = stakingPool.getDepositAmount(id);
        uint tot = uint(x) + uint(y);
        assertEq(tot, depAmt2);
      } else if(x == 0) {
        vm.expectRevert("must deposit ether");
        startHoax(alice);
        stakingPool.depositToPool{value: x}();
      } else { //uint64 cannot be > 32 ether (max 18,446,744,073,709,551,615 or ~18.45 ether)
        startHoax(alice);
        stakingPool.depositToPool{value: x}();
        uint id = frensPoolShare.tokenOfOwnerByIndex(alice, 0);
        vm.expectRevert("total deposits cannot be more than 32 Eth");
        stakingPool.addToDeposit{value: y}(id);
      }
    }

    function testAddToDepositWrongPool(uint64 x, uint64 y) public {
      if(x > 0 && uint(x) + uint(y) <= 32 ether){
        startHoax(alice);
        stakingPool.depositToPool{value: x}();
        uint id = frensPoolShare.tokenOfOwnerByIndex(alice, 0);
        assertTrue(id != 0 );
        uint depAmt = stakingPool.getDepositAmount(id);
        assertEq(x, depAmt);
        //should throw for wrong pool
        vm.expectRevert("wrong staking pool");
        stakingPool2.addToDeposit{value: y}(id);
        //existing id should work fine (redundant with previous test)
        stakingPool.addToDeposit{value: y}(id);
        uint depAmt2 = stakingPool.getDepositAmount(id);
        uint tot = uint(x) + uint(y);
        assertEq(tot, depAmt2);
      } else if(x == 0) {
        vm.expectRevert("must deposit ether");
        startHoax(alice);
        stakingPool.depositToPool{value: x}();
      } else { //uint64 cannot be > 32 ether (max 18,446,744,073,709,551,615 or ~18.45 ether)
        startHoax(alice);
        stakingPool.depositToPool{value: x}();
        uint id = frensPoolShare.tokenOfOwnerByIndex(alice, 0);
        vm.expectRevert("total deposits cannot be more than 32 Eth");
        stakingPool.addToDeposit{value: y}(id);
      }
    }

    function testWithdraw(uint72 x, uint72 y) public {
      if(x >= y && x > 0 && uint(x) <= 32 ether){
        startHoax(alice);
        stakingPool.depositToPool{value: x}();
        uint id = frensPoolShare.tokenOfOwnerByIndex(alice, 0);
        assertTrue(id != 0 );
        uint depAmt = stakingPool.getDepositAmount(id);
        assertEq(x, depAmt);
        stakingPool.withdraw(id, y);
        uint depAmt2 = stakingPool.getDepositAmount(id);
        uint tot = uint(x) - uint(y);
        assertEq(tot, depAmt2);
      } else if(x == 0) {
        vm.expectRevert("must deposit ether");
        startHoax(alice);
        stakingPool.depositToPool{value: x}();
      } else if(uint(x) > 32 ether) {
        vm.expectRevert("total deposits cannot be more than 32 Eth");
        startHoax(alice);
        stakingPool.depositToPool{value: x}();
      } else {
        startHoax(alice);
        stakingPool.depositToPool{value: x}();
        uint id = frensPoolShare.tokenOfOwnerByIndex(alice, 0);
        assertTrue(id != 0 );
        vm.expectRevert("not enough deposited");
        stakingPool.withdraw(id, y);
      }
    }

    function testStake() public { 
      //stakingPool.sendToOwner();
      uint initialBalance = address(stakingPool).balance; //bc someone sent eth to this address on mainnet.
      hoax(alice);
      stakingPool.depositToPool{value: 32000000000000000000}();
      assertEq(initialBalance + 32000000000000000000, address(stakingPool).balance);
      bytes32 deposit_count_hash = keccak256(depositContract.get_deposit_count());
      hoax(contOwner);
      //for this test to pass, it must be run on a mainnet fork,
      //and the vlaues below must all be correctly gererated in the staking_deposit_cli
      //use: ./deposit new-mnemonic --num_validators 1 --chain mainnet --eth1_withdrawal_address
      //followed by the stakingPool contract address
      stakingPool.stake(pubkey, withdrawal_credentials, signature, deposit_data_root);
      assertEq(initialBalance, address(stakingPool).balance);
      assertFalse(keccak256(depositContract.get_deposit_count()) == deposit_count_hash);
      //test reverts for trying to deposit when staked
      startHoax(alice);
      vm.expectRevert("not accepting deposits");
      stakingPool.depositToPool{value: 1}();
      vm.expectRevert("not accepting deposits");
      stakingPool.addToDeposit{value: 1}(1);
    }

    function testStakeTwoStep() public { 
      uint initialBalance = address(stakingPool).balance; //bc someone sent eth to this address on mainnet.
      hoax(alice);
      stakingPool.depositToPool{value: 32000000000000000000}();
      assertEq(initialBalance + 32000000000000000000, address(stakingPool).balance);
      bytes32 deposit_count_hash = keccak256(depositContract.get_deposit_count());
      startHoax(contOwner);
      //for this test to pass, it must be run on a mainnet fork,
      //and the vlaues below must all be correctly gererated in the staking_deposit_cli
      //use: ./deposit new-mnemonic --num_validators 1 --chain mainnet --eth1_withdrawal_address
      //followed by the stakingPool contract address
      stakingPool.setPubKey(pubkey, withdrawal_credentials, signature, deposit_data_root);
      stakingPool.stake();
      assertEq(initialBalance, address(stakingPool).balance);
      assertFalse(keccak256(depositContract.get_deposit_count()) == deposit_count_hash);
    }

    function testDistribute(uint32 x, uint32 y) public {
      uint maxUint32 = 4294967295;
      uint aliceDeposit = uint(x) * 31999999999999999999 / maxUint32;
      uint bobDeposit = 32000000000000000000 - aliceDeposit;
      if(x != 0 && y > 100){
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
        assertApproxEqAbs(aliceBalance, aliceBalanceExpected, 2);
        uint bobBalanceExpected = bobBalance + bobShare;
        bobBalance = address(bob).balance;
        //to account for rounding errors max 2 wei (bc we subtract 1 wei in contract to avoid drawing negative)
        assertApproxEqAbs(bobBalance, bobBalanceExpected, 2);

      } else if(x == 0) {
        vm.expectRevert("must deposit ether");
        startHoax(alice);
        stakingPool.depositToPool{value: x}();
      } else {
        hoax(alice);
        stakingPool.depositToPool{value: aliceDeposit}();
        hoax(bob);
        stakingPool.depositToPool{value: bobDeposit}();
        startHoax(contOwner);
        stakingPool.stake(pubkey, withdrawal_credentials, signature, deposit_data_root);
        payable(stakingPool).transfer(y);
        vm.expectRevert("minimum of 100 wei to distribute");
        stakingPool.distribute();
      }

    }

    function testBadWithdrawalCred() public {
      startHoax(contOwner);
      vm.expectRevert("withdrawal credential mismatch");
      stakingPool.setPubKey(pubkey, hex"01000000000000000000000000dead", signature, deposit_data_root);
      vm.expectRevert("withdrawal credential mismatch");
      stakingPool.stake(pubkey, hex"01000000000000000000000000dead", signature, deposit_data_root);
    }

    function testPubKeyMismatch() public {
      startHoax(contOwner);
      stakingPool.setPubKey(pubkey, withdrawal_credentials, signature, deposit_data_root);
      vm.expectRevert("pubKey mismatch");
      stakingPool.stake(hex"dead", withdrawal_credentials, signature, deposit_data_root);
    }

}
