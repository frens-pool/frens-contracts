// deploy/00_deploy_your_contract.js

const { ethers } = require("hardhat");

const localChainId = "31337";

// const sleep = (ms) =>
//   new Promise((r) =>
//     setTimeout(() => {
//       console.log(`waited for ${(ms / 1000).toFixed(3)} seconds`);
//       r();
//     }, ms)
//   );

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = await getChainId();

  console.log("chainId", chainId);
  const ENS = "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e";

  var SSVRegistry = 0;
  var DepositContract = 0;

  if(chainId == 1){
    SSVRegistry = "0xb9e155e65B5c4D66df28Da8E9a0957f06F11Bc04"; //update when SSV exists on mainnet
    DepositContract = "0x00000000219ab540356cBB839Cbe05303d7705Fa";
    console.log("deploying to mainnet")
  } else if(chainId == 5) {
    SSVRegistry = "0xb9e155e65B5c4D66df28Da8E9a0957f06F11Bc04";
    DepositContract = "0xff50ed3d0ec03aC01D4C79aAd74928BFF48a7b2b";
  }else if(chainId ==31337){ //assumes we are forking goerli to test
    SSVRegistry = "0xb9e155e65B5c4D66df28Da8E9a0957f06F11Bc04";
    DepositContract = "0xff50ed3d0ec03aC01D4C79aAd74928BFF48a7b2b";
  }

  var FrensStorageOld = 0;
  var FactoryProxyOld = 0;
  var FrensInitialiserOld = 0;
  var FrensManagerOld = 0;
  var FrensPoolShareOld = 0;
  var StakingPoolFactoryOld = 0;
  var FrensClaimOld = 0;
  var FrensPoolSetterOld = 0;
  var FrensMetaHelperOld = 0;
  var FrensPoolShareTokenURIOld = 0;
  var FrensArtOld = 0;

  try{
    FrensStorageOld = await ethers.getContract("FrensStorage", deployer);
  } catch(e) {}

  try{
    FactoryProxyOld = await ethers.getContract("FactoryProxy", deployer);
  } catch(e) {}

  try{
    FrensInitialiserOld = await ethers.getContract("FrensInitialiser", deployer);
  } catch(e) {}

  try{
    FrensManagerOld = await ethers.getContract("FrensManager", deployer);
  } catch(e) {}

  try{
    FrensPoolShareOld = await ethers.getContract("FrensPoolShare", deployer);
  } catch(e) {}

  try{
    StakingPoolFactoryOld = await ethers.getContract("StakingPoolFactory", deployer);
  } catch(e) {}

  try{
    FrensClaimOld = await ethers.getContract("FrensClaim", deployer);
  } catch(e) {}

  try{
    FrensPoolSetterOld = await ethers.getContract("FrensPoolSetter", deployer);
  } catch(e) {}

  try{
    FrensMetaHelperOld = await ethers.getContract("FrensMetaHelper", deployer);
  } catch(e) {}

  try{
    FrensPoolShareTokenURIOld = await ethers.getContract("FrensPoolShareTokenURI", deployer);
  } catch(e) {}

  try{
    FrensArtOld = await ethers.getContract("FrensArt", deployer);
  } catch(e) {}

  
  if(FrensStorageOld == 0 || chainId == 31337){ //should not update storage contract on testnet of mainnet
    await deploy("FrensStorage", {
      // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
      from: deployer,
      args: [
        //no args
       ],
      log: true,
      waitConfirmations: 5,
    });
  }
  var reinitialiseEverything = false;
  const FrensStorage = await ethers.getContract("FrensStorage", deployer);
  console.log("storage contract", FrensStorage.address);
  if(FrensStorageOld == 0){
    reinitialiseEverything = true;
    console.log('\x1b[33m%s\x1b[0m', "FrensStorage initialising", FrensStorage.address);
  } else if(FrensStorageOld.address != FrensStorage.address){
    reinitialiseEverything = true;
    console.log('\x1b[31m%s\x1b[0m', "FrensStorage updated and initialising", FrensStorage.address);
  }

  if(FactoryProxyOld == 0 || chainId == 31337){ //should not update proxy contract on testnet of mainnet
    await deploy("FactoryProxy", {
      // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
      from: deployer,
      args: [  FrensStorage.address ],
      log: true,
      waitConfirmations: 5,
    });
  }

  const FactoryProxy = await ethers.getContract("FactoryProxy", deployer);

  if(FactoryProxyOld == 0){
    console.log('\x1b[33m%s\x1b[0m', "FactoryProxy initialised", FactoryProxy.address);
  } else if(FactoryProxyOld.address != FactoryProxy.address){
    console.log('\x1b[31m%s\x1b[0m', "FactoryProxy updated", FactoryProxy.address);
  }

  await deploy("FrensInitialiser", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    args: [  FrensStorage.address ],
    log: true,
    waitConfirmations: 5,
  });

  const FrensInitialiser = await ethers.getContract("FrensInitialiser", deployer);

  if(FrensInitialiserOld == 0 || reinitialiseEverything) {
    const initialiserInit = await FrensInitialiser.setContract(FrensInitialiser.address, "FrensInitialiser");
    await initialiserInit.wait();
    const frensInitBoolTrue = await FrensInitialiser.setContractExists(FrensInitialiser.address, true); //grants privileges to write to FrensStorage
    await frensInitBoolTrue.wait();
    //ssvRegistry
    const ssvInit = await FrensInitialiser.setExternalContract(SSVRegistry, "SSVRegistry");
    await ssvInit.wait();
    //deposit contract
    const depContInit = await FrensInitialiser.setExternalContract(DepositContract, "DepositContract");
    await depContInit.wait();
    //ENS
    const ENSInit = await FrensInitialiser.setExternalContract(ENS, "ENS");
    await ENSInit.wait();
    console.log('\x1b[33m%s\x1b[0m', "initialiser initialised", FrensInitialiser.address);
  } else if(FrensInitialiserOld.address != FrensInitialiser.address) {
    const newInitExist = await FrensInitialiserOld.setContractExists(FrensInitialiser.address, true); //grants privileges to write to FrensStorage
    await newInitExist.wait();
    const initialiserDel = await FrensInitialiser.deleteContract(FrensInitialiserOld.address,"FrensInitialiser");
    await initialiserDel.wait();
    const initialiserInit = await FrensInitialiser.setContract(FrensInitialiser.address, "FrensInitialiser");
    await initialiserInit.wait();
    console.log('\x1b[36m%s\x1b[0m', "initialiser updated", FrensInitialiser.address);
  }

  await deploy("FrensManager", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    args: [  FrensStorage.address ],
    log: true,
    waitConfirmations: 5,
  });

  const FrensManager = await ethers.getContract("FrensManager", deployer);

  if(FrensManagerOld == 0 || reinitialiseEverything) {
    const managerInit = await FrensInitialiser.setContract(FrensManager.address, "FrensManager");
    await managerInit.wait();
    const frensManageBoolTrue = await FrensInitialiser.setContractExists(FrensManager.address, true); //grants privileges to write to FrensStorage
    await frensManageBoolTrue.wait();
   
    console.log('\x1b[33m%s\x1b[0m', "manager initialised", FrensManager.address);
  } else if(FrensManagerOld.address != FrensManager.address) {
    const managerDel = await FrensInitialiser.deleteContract(FrensManagerOld.address,"FrensManager");
    await managerDel.wait();
    const managerInit = await FrensInitialiser.setContract(FrensManager.address, "FrensManager");
    await managerInit.wait();
    const newManageExist = await FrensInitialiser.setContractExists(FrensManager.address, true); //grants privileges to write to FrensStorage
    await newManageExist.wait();
    console.log('\x1b[36m%s\x1b[0m', "manager updated", FrensManager.address);
  }


  if(FrensPoolShareOld == 0 || chainId == 31337){ //should not update NFT contract on testnet or mainnet
    await deploy("FrensPoolShare", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    args: [
      //"0x00000000219ab540356cBB839Cbe05303d7705Fa", "0xb9e155e65B5c4D66df28Da8E9a0957f06F11Bc04" //mainnet (using goerli ssvRegistryAddress until there is a mainnet deployment - some features will not work on mainnet fork)
      FrensStorage.address
     ],
    log: true,
    waitConfirmations: 5,
    });
  }

  const FrensPoolShare = await ethers.getContract("FrensPoolShare", deployer);

  if(FrensPoolShareOld == 0){
    const poolShareXfer = await FrensPoolShare.transferOwnership("0xa53A6fE2d8Ad977aD926C485343Ba39f32D3A3F6");
    await poolShareXfer.wait();
    const poolShareInit = await FrensInitialiser.setContract(FrensPoolShare.address, "FrensPoolShare");
    await poolShareInit.wait();
    const nftBoolFalse = await FrensInitialiser.setContractExists(FrensPoolShare.address, false); //removes privileges to write to FrensStorage
    await nftBoolFalse.wait();
    console.log('\x1b[33m%s\x1b[0m', "FrensPoolShare initialised", FrensPoolShare.address);
  } else if(FrensPoolShareOld.address != FrensPoolShare.address){
    const poolShareXfer = await FrensPoolShare.transferOwnership("0xa53A6fE2d8Ad977aD926C485343Ba39f32D3A3F6");
    await poolShareXfer.wait();
    const poolShareDel = await FrensInitialiser.deleteContract(FrensPoolShareOld.address, "FrensPoolShare");
    await poolShareDel.wait();
    const poolShareInit = await FrensInitialiser.setContract(FrensPoolShare.address, "FrensPoolShare");
    await poolShareInit.wait();
    const nftBoolFalse = await FrensInitialiser.setContractExists(FrensPoolShare.address, false); //removes privileges to write to FrensStorage
    await nftBoolFalse.wait();
    console.log('\x1b[31m%s\x1b[0m', "FrensPoolShare updated", FrensPoolShare.address);
  }else if(reinitialiseEverything) {
    const poolShareInit = await FrensInitialiser.setContract(FrensPoolShare.address, "FrensPoolShare");
    await poolShareInit.wait();
    const nftBoolFalse = await FrensInitialiser.setContractExists(FrensPoolShare.address, false); //removes privileges to write to FrensStorage
    await nftBoolFalse.wait();
    console.log('\x1b[33m%s\x1b[0m', "FrensPoolShare (re)initialised", FrensPoolShare.address);
  }

  await deploy("StakingPoolFactory", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    args: [
      //"0x00000000219ab540356cBB839Cbe05303d7705Fa", "0xb9e155e65B5c4D66df28Da8E9a0957f06F11Bc04" //mainnet (using goerli ssvRegistryAddress until there is a mainnet deployment - some features will not work on mainnet fork)
      FrensStorage.address //goerli
     ],
    log: true,
    waitConfirmations: 5,
  });

  const StakingPoolFactory = await ethers.getContract("StakingPoolFactory", deployer);

  if(StakingPoolFactoryOld == 0 || reinitialiseEverything) {
    const factoryInit = await FrensInitialiser.setContract(StakingPoolFactory.address, "StakingPoolFactory");
    await factoryInit.wait();
    const factoryBoolTrue = await FrensInitialiser.setContractExists(StakingPoolFactory.address, false); //grants privileges to write to FrensStorage
    await factoryBoolTrue.wait();
    console.log('\x1b[33m%s\x1b[0m', "StakingPoolFactory initialised", StakingPoolFactory.address);
  } else if(StakingPoolFactoryOld.address != StakingPoolFactory.address){
    const factoryDel = await FrensInitialiser.deleteContract(StakingPoolFactoryOld.address, "StakingPoolFactory");
    await factoryDel.wait();
    const factoryInit = await FrensInitialiser.setContract(StakingPoolFactory.address, "StakingPoolFactory");
    await factoryInit.wait();
    const factoryBoolTrue = await FrensInitialiser.setContractExists(StakingPoolFactory.address, false); //grants privileges to write to FrensStorage
    await factoryBoolTrue.wait();
    console.log('\x1b[36m%s\x1b[0m', "StakingPoolFactory updated", StakingPoolFactory.address);
  }

  await deploy("FrensClaim", {
    from: deployer,
    args: [
      FrensStorage.address //goerli
     ],
    log: true,
    waitConfirmations: 5,
  });

  const FrensClaim = await ethers.getContract("FrensClaim", deployer);

  if(FrensClaimOld == 0 || reinitialiseEverything) {
    const frensClaimInit = await FrensInitialiser.setContract(FrensClaim.address, "FrensClaim");
    await frensClaimInit.wait();
    const frensClaimBoolTrue = await FrensInitialiser.setContractExists(FrensClaim.address, true); //grants privileges to write to FrensStorage
    await frensClaimBoolTrue.wait();
    console.log('\x1b[33m%s\x1b[0m', "FrensClaim initialised", FrensClaim.address);
  } else if(FrensClaimOld.address != FrensClaim.address){
    const frensClaimDel = await FrensInitialiser.deleteContract(FrensClaimOld.address, "FrensClaim");
    await frensClaimDel.wait();
    const frensClaimInit = await FrensInitialiser.setContract(FrensClaim.address, "FrensClaim");
    await frensClaimInit.wait();
    const frensClaimBoolTrue = await FrensInitialiser.setContractExists(FrensClaim.address, true); //grants privileges to write to FrensStorage
    await frensClaimBoolTrue.wait();
    console.log('\x1b[36m%s\x1b[0m', "FrensClaim updated", FrensClaim.address);
  }

  await deploy("FrensPoolSetter", {
    from: deployer,
    args: [
      FrensStorage.address //goerli
     ],
    log: true,
    waitConfirmations: 5,
  });

  const FrensPoolSetter = await ethers.getContract("FrensPoolSetter", deployer);

  if(FrensPoolSetterOld == 0 || reinitialiseEverything) {
    const FrensPoolSetterInit = await FrensInitialiser.setContract(FrensPoolSetter.address, "FrensPoolSetter");
    await FrensPoolSetterInit.wait();
    const FrensPoolSetterBoolTrue = await FrensInitialiser.setContractExists(FrensPoolSetter.address, true); //grants privileges to write to FrensStorage
    await FrensPoolSetterBoolTrue.wait();
    console.log('\x1b[33m%s\x1b[0m', "FrensPoolSetter initialised", FrensPoolSetter.address);
  } else if(FrensPoolSetterOld.address != FrensPoolSetter.address){
    const FrensPoolSetterDel = await FrensInitialiser.deleteContract(FrensPoolSetterOld.address, "FrensPoolSetter");
    await FrensPoolSetterDel.wait();
    const FrensPoolSetterInit = await FrensInitialiser.setContract(FrensPoolSetter.address, "FrensPoolSetter");
    await FrensPoolSetterInit.wait();
    const FrensPoolSetterBoolTrue = await FrensInitialiser.setContractExists(FrensPoolSetter.address, true); //grants privileges to write to FrensStorage
    await FrensPoolSetterBoolTrue.wait();
    console.log('\x1b[36m%s\x1b[0m', "FrensPoolSetter updated", FrensPoolSetter.address);
  }

  await deploy("FrensMetaHelper", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    args: [
      FrensStorage.address
     ],
    log: true,
    waitConfirmations: 5,
  });

  const FrensMetaHelper = await ethers.getContract("FrensMetaHelper", deployer);

  if(FrensMetaHelperOld == 0 || reinitialiseEverything){
    const meatInit = await FrensInitialiser.setContract(FrensMetaHelper.address, "FrensMetaHelper");
    await meatInit.wait();
    const metaBoolFalse = await FrensInitialiser.setContractExists(FrensMetaHelper.address, false); //removes privileges to write to FrensStorage
    await metaBoolFalse.wait();
    console.log('\x1b[33m%s\x1b[0m', "FrensMetaHelper initialised", FrensMetaHelper.address);
  } else if(FrensMetaHelperOld.address != FrensMetaHelper.address){
    const metaDel = await FrensInitialiser.deleteContract(FrensMetaHelperOld.address, "FrensMetaHelper");
    await metaDel.wait();
    const meatInit = await FrensInitialiser.setContract(FrensMetaHelper.address, "FrensMetaHelper");
    await meatInit.wait();
    const metaBoolFalse = await FrensInitialiser.setContractExists(FrensMetaHelper.address, false); //removes privileges to write to FrensStorage
    await metaBoolFalse.wait();
    console.log('\x1b[36m%s\x1b[0m', "FrensMetaHelper updated", FrensMetaHelper.address);
  }

  await deploy("FrensPoolShareTokenURI", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    args: [  FrensStorage.address ],
    log: true,
    waitConfirmations: 5,
  });

  const FrensPoolShareTokenURI = await ethers.getContract("FrensPoolShareTokenURI", deployer);

  if(FrensPoolShareTokenURIOld == 0 || reinitialiseEverything){
    const tokUriInit = await FrensInitialiser.setContract(FrensPoolShareTokenURI.address, "FrensPoolShareTokenURI");
    await tokUriInit.wait();
    const uriBoolFalse = await FrensInitialiser.setContractExists(FrensPoolShareTokenURI.address, false); //removes privileges to write to FrensStorage
    await uriBoolFalse.wait();
    console.log('\x1b[33m%s\x1b[0m', "FrensPoolShareTokenURI initialised", FrensPoolShareTokenURI.address);
  } else if(FrensPoolShareTokenURIOld.address != FrensPoolShareTokenURI.address){
    const tokUriDel = await FrensInitialiser.deleteContract(FrensPoolShareTokenURIOld.address, "FrensPoolShareTokenURI");
    await tokUriDel.wait();
    const tokUriInit = await FrensInitialiser.setContract(FrensPoolShareTokenURI.address, "FrensPoolShareTokenURI");
    await tokUriInit.wait();
    const uriBoolFalse = await FrensInitialiser.setContractExists(FrensPoolShareTokenURI.address, false); //removes privileges to write to FrensStorage
    await uriBoolFalse.wait();
    console.log('\x1b[36m%s\x1b[0m', "FrensPoolShareTokenURI updated", FrensPoolShareTokenURI.address);
  }

  await deploy("FrensArt", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    args: [
      FrensStorage.address
     ],
    log: true,
    waitConfirmations: 5,
  });

  const FrensArt = await ethers.getContract("FrensArt", deployer);

  if(FrensArtOld == 0 || reinitialiseEverything){
    const artInit = await FrensInitialiser.setContract(FrensArt.address, "FrensArt");
    await artInit.wait();
    const artBoolFalse = await FrensInitialiser.setContractExists(FrensArt.address, false); //removes privileges to write to FrensStorage
    await artBoolFalse.wait();
    console.log('\x1b[33m%s\x1b[0m', "FrensArt initialised", FrensArt.address);
  } else if(FrensArtOld.address != FrensArt.address){
    const artDel = await FrensInitialiser.deleteContract(FrensArtOld.address, "FrensArt");
    await artDel.wait();
    const artInit = await FrensInitialiser.setContract(FrensArt.address, "FrensArt");
    await artInit.wait();
    const artBoolFalse = await FrensInitialiser.setContractExists(FrensArt.address, false); //removes privileges to write to FrensStorage
    await artBoolFalse.wait();
    console.log('\x1b[36m%s\x1b[0m', "FrensArt updated", FrensArt.address);
  }

//deploying a pool for verification purposes only (is this necessary?)
  await deploy("StakingPool", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    args: [
      "0x521B2cE927FD6d0D473789Bd3c70B296BBce613e",
      false,
      FrensStorage.address
    ],
    log: true,
    waitConfirmations: 5,
  });

  if(reinitialiseEverything){
    const setDeployed = await FrensStorage.setDeployedStatus();
    await setDeployed.wait();
    console.log('\x1b[33m%s\x1b[0m', "FRENS Group Contracts Deployed");
  }

  const newPool = await StakingPoolFactory.create("0x42f58dd8528c302eeC4dCbC71159bA737908D6Fa", false/*, false, 0, 32000000000000000000n*/);
  
  newPoolResult = await newPool.wait();
  console.log("new pool", newPoolResult.logs[0].address);
/*
  await deploy("FrensArtTest", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    args: [
      FrensStorage.address
     ],
    log: true,
    waitConfirmations: 5,
  });

  const FrensArtTest = await ethers.getContract("FrensArtTest", deployer);
  console.log("FrensArtTest", FrensArtTest.address);
*/
};
module.exports.tags = ["FrensPoolShare", "StakingPoolFactory", "StakingPool", "FrensStorage", "FrensInitialiser", "FrensPoolShareTokenURI"];
