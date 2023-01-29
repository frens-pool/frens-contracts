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
import "../../contracts/FrensClaim.sol";
import "../../contracts/FrensPoolSetter.sol";
import "../../contracts/FrensPoolShare.sol";
import "../../contracts/interfaces/IStakingPoolFactory.sol";
import "../../contracts/interfaces/IDepositContract.sol";
import "./TestHelper.sol";


contract MiscTest is Test {
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
    FrensClaim public frensClaim;
    FrensPoolSetter public frensPoolSetter;

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
      frensInitialiser.setContractExists(address(frensInitialiser), true);
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
      frensInitialiser.setContractExists(address(frensPoolShare), false);
      //deploy Factory
      stakingPoolFactory = new StakingPoolFactory(frensStorage);
      //initialise Factory
      frensInitialiser.setContract(address(stakingPoolFactory), "StakingPoolFactory");
      frensInitialiser.setContractExists(address(stakingPoolFactory), true);
      //deploy Claims
      frensClaim = new FrensClaim(frensStorage);
      //initialise Claims
      frensInitialiser.setContract(address(frensClaim), "FrensClaim");
      frensInitialiser.setContractExists(address(frensClaim), true);
      //deploy PoolSetter
      frensPoolSetter = new FrensPoolSetter(frensStorage);
      //initialise PoolSetter
      frensInitialiser.setContract(address(frensPoolSetter), "FrensPoolSetter");
      frensInitialiser.setContractExists(address(frensPoolSetter), true);
      //deploy MetaHelper
      frensMetaHelper = new FrensMetaHelper(frensStorage);
      //initialise Metahelper
      frensInitialiser.setContract(address(frensMetaHelper), "FrensMetaHelper");
      frensInitialiser.setContractExists(address(frensMetaHelper), false);
      //deploy TokenURI
      frensPoolShareTokenURI = new FrensPoolShareTokenURI(frensStorage);
      //Initialise TokenURI
      frensInitialiser.setContract(address(frensPoolShareTokenURI), "FrensPoolShareTokenURI");
      frensInitialiser.setContractExists(address(frensPoolShareTokenURI), false);
      //deployArt
      frensArt = new FrensArt(frensStorage);
      //initialise art
      frensInitialiser.setContract(address(frensArt), "FrensArt");
      frensInitialiser.setContractExists(address(frensArt), false);
      //set contracts as deployed
      //tx.origin must be this contract
      vm.prank(address(this), address(this));
      frensStorage.setDeployedStatus();

      //create staking pool through proxy contract
      (address pool) = proxy.create(contOwner, false/*, false, 0, 32000000000000000000*/);
      //connect to staking pool
      stakingPool = StakingPool(payable(pool));
      //console.log the pool address for fun  if(FrensPoolShareOld == 0){
      //console.log("pool", pool);

      //create a second staking pool through proxy contract
      (address pool2) = proxy.create(contOwner, false/*, false, 0, 32000000000000000000*/);
      //connect to staking pool
      stakingPool2 = StakingPool(payable(pool2));
      //console.log the pool address for fun  if(FrensPoolShareOld == 0){
      //console.log("pool2", pool2);

    }

    function testMintingDirectly() public {
      hoax(alice);
      vm.expectRevert("Invalid Pool");
      frensPoolShare.mint(address(alice));
    }

    function testApprove() public {
      startHoax(alice);
      uint i = 1;
      while( i < 255 ){ //255 is arbitrarily chosen, the point is to check a few different values.
        stakingPool.depositToPool{value: 1}();
 
        uint id = frensPoolShare.tokenOfOwnerByIndex(alice, i-1);
        assertTrue(id == i );

        address shouldBeZero = frensPoolShare.getApproved(i);
        assertEq(address(0), shouldBeZero);

        frensPoolShare.approve(bob, i);
        address shouldBeBob = frensPoolShare.getApproved(i);
        assertEq(bob, shouldBeBob);
        i++;
      }
    }

    function testBalanceOf() public {
      startHoax(alice);
      uint i = 1;
      while( i < 255 ){
        stakingPool.depositToPool{value: 1}();
        uint id = frensPoolShare.tokenOfOwnerByIndex(alice, i-1);
        assertTrue(id == i );
        uint balanceOfAlice = frensPoolShare.balanceOf(alice);
        assertEq(balanceOfAlice, i);
        i++;
      }
    }

    function testexists() public {
      startHoax(alice);
      
      uint i = 1;
       while( i < 255 ){
        assertFalse(frensPoolShare.exists(i));
        stakingPool.depositToPool{value: 1}();
        assertTrue(frensPoolShare.exists(i));
        i++;
      }
      
    }

    function testGetPoolById() public {
      startHoax(alice);
      uint i = 1;
      while( i < 255 ){
        stakingPool.depositToPool{value: 1}();
        address sbStakingPool = frensPoolShare.getPoolById(i);
        assertEq(address(stakingPool), sbStakingPool);
        i++;
        stakingPool2.depositToPool{value: 1}();
        address sbStakingPool2 = frensPoolShare.getPoolById(i);
        assertEq(address(stakingPool2), sbStakingPool2);
        i++;
        stakingPool.depositToPool{value: 1}(); //one more to throw off the even/odd thing for fun
        sbStakingPool = frensPoolShare.getPoolById(i);
        assertEq(address(stakingPool), sbStakingPool);
        i++; 
      }
    }

    function testIsApprovedForAll() public {
      startHoax(alice);
      uint i = 1;
      while( i < 64 ){
        stakingPool.depositToPool{value: 1}();
        i++;
      }
      assertFalse(frensPoolShare.isApprovedForAll(alice, bob));
      frensPoolShare.setApprovalForAll(bob, true);
      assertTrue(frensPoolShare.isApprovedForAll(alice, bob));
    }

    function testOwner() public {
      assertEq(address(this), frensPoolShare.owner());
      hoax(alice);
      vm.expectRevert("Ownable: caller is not the owner");
      frensPoolShare.transferOwnership(bob);
      hoax(address(this));
      frensPoolShare.transferOwnership(bob);
      assertEq(bob, frensPoolShare.owner());
    }

    function testOwnerOf() public {
      uint i = 1;
      while( i < 255 ){
        hoax(alice);
        stakingPool.depositToPool{value: 1}();
        address sbAlice = frensPoolShare.ownerOf(i);
        assertEq(alice, sbAlice);
        i++;
        hoax(bob);
        stakingPool2.depositToPool{value: 1}();
        address sbBob = frensPoolShare.ownerOf(i);
        assertEq(bob, sbBob);
        i++;
        hoax(bob);
        stakingPool.depositToPool{value: 1}(); //one more to throw off the even/odd thing for fun
        sbBob = frensPoolShare.ownerOf(i);
        assertEq(bob, sbBob);
        i++; 
      }
    }

    function testSafeTransferFrom() public {
      hoax(alice);
      stakingPool.depositToPool{value: 1}();
      uint id = frensPoolShare.tokenOfOwnerByIndex(alice, 0);
      assertEq(alice, frensPoolShare.ownerOf(id));
      hoax(bob);
      vm.expectRevert("ERC721: transfer caller is not owner nor approved");
      frensPoolShare.safeTransferFrom(alice, bob, id);
      hoax(alice);
      frensPoolShare.safeTransferFrom(alice, bob, id);
      assertEq(bob, frensPoolShare.ownerOf(id));
      hoax(bob);
      vm.expectRevert("ERC721: transfer to non ERC721Receiver implementer");
      frensPoolShare.safeTransferFrom(bob, address(frensStorage), id);

      NftReceiver nftReceiver = new NftReceiver();
      hoax(bob);
      frensPoolShare.safeTransferFrom(bob, address(nftReceiver), id);
      assertEq(address(nftReceiver), frensPoolShare.ownerOf(id));

    }

    function testTokenByIndex() public {
      startHoax(alice);
      uint i = 1;
      while( i < 255 ){
        stakingPool.depositToPool{value: 1}();
        uint id = frensPoolShare.tokenByIndex(i-1);
        assertTrue(id == i );
        i++;
      }
    }

    function testTransferFrom() public {
      hoax(alice);
      stakingPool.depositToPool{value: 1}();
      uint id = frensPoolShare.tokenOfOwnerByIndex(alice, 0);
      assertEq(alice, frensPoolShare.ownerOf(id));
      hoax(bob);
      vm.expectRevert("ERC721: transfer caller is not owner nor approved");
      frensPoolShare.transferFrom(alice, bob, id);
      hoax(alice);
      frensPoolShare.transferFrom(alice, bob, id);
      
    }




}
