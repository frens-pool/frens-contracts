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

  var FrensPoolShareOld = 0;
  var FactoryProxyOld = 0;
  var FrensInitialiserOld = 0;
  var FrensStorageOld = 0;
  var StakingPoolFactoryOld = 0;
  var FrensPoolShareTokenURIOld = 0;
  var FrensMetaHelperOld = 0;
  var FrensArtOld = 0;

  try{
    FrensPoolShareOld = await ethers.getContract("FrensPoolShare", deployer);
  } catch(e) {}

  try{
    FactoryProxyOld = await ethers.getContract("FactoryProxy", deployer);
  } catch(e) {}

  try{
    FrensInitialiserOld = await ethers.getContract("FrensInitialiser", deployer);
  } catch(e) {}

  try{
    FrensStorageOld = await ethers.getContract("FrensStorage", deployer);
  } catch(e) {}

  try{
    StakingPoolFactoryOld = await ethers.getContract("StakingPoolFactory", deployer);
  } catch(e) {}

  try{
    FrensPoolShareTokenURIOld = await ethers.getContract("FrensPoolShareTokenURI", deployer);
  } catch(e) {}

  try{
    FrensMetaHelperOld = await ethers.getContract("FrensMetaHelper", deployer);
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

  const FrensStorage = await ethers.getContract("FrensStorage", deployer);

  if(FrensStorageOld == 0){
    console.log('\x1b[33m%s\x1b[0m', "FrensStorage initialised", FrensStorage.address);
  } else if(FrensStorageOld.address != FrensStorage.address){
    console.log('\x1b[31m%s\x1b[0m', "FrensStorage updated", FrensStorage.address);
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

  if(FrensInitialiserOld == 0) {
    await FrensInitialiser.setContract(FrensInitialiser.address, "FrensInitialiser");
    //ssvRegistry
    await FrensInitialiser.setExternalContract("0xb9e155e65B5c4D66df28Da8E9a0957f06F11Bc04", "SSVRegistry") //goerli
    //deposit contract
    await FrensInitialiser.setExternalContract("0xff50ed3d0ec03aC01D4C79aAd74928BFF48a7b2b", "DepositContract") //goerli
    console.log('\x1b[33m%s\x1b[0m', "initialiser initialised", FrensInitialiser.address);
  } else if(FrensInitialiserOld.address != FrensInitialiser.address) {
    await FrensInitialiser.deleteContract(FrensInitialiserOld.address,"FrensInitialiser");
    await FrensInitialiser.setContract(FrensInitialiser.address, "FrensInitialiser");
    console.log('\x1b[36m%s\x1b[0m', "initialiser updated", FrensInitialiser.address);
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
    await FrensPoolShare.transferOwnership("0xa53A6fE2d8Ad977aD926C485343Ba39f32D3A3F6");
    await FrensInitialiser.setContract(FrensPoolShare.address, "FrensPoolShare");
    console.log('\x1b[33m%s\x1b[0m', "FrensPoolShare initialised", FrensPoolShare.address);
  } else if(FrensPoolShareOld.address != FrensPoolShare.address){
    await FrensPoolShare.transferOwnership("0xa53A6fE2d8Ad977aD926C485343Ba39f32D3A3F6");
    await FrensInitialiser.deleteContract(FrensPoolShareOld.address, "FrensPoolShare");
    await FrensInitialiser.setContract(FrensPoolShare.address, "FrensPoolShare");
    console.log('\x1b[31m%s\x1b[0m', "FrensPoolShare updated", FrensPoolShare.address);
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

  if(StakingPoolFactoryOld == 0) {
    await FrensInitialiser.setContract(StakingPoolFactory.address, "StakingPoolFactory");
    console.log('\x1b[33m%s\x1b[0m', "StakingPoolFactory initialised", StakingPoolFactory.address);
  } else if(StakingPoolFactoryOld.address != StakingPoolFactory.address){
    await FrensInitialiser.deleteContract(StakingPoolFactoryOld.address, "StakingPoolFactory");
    await FrensInitialiser.setContract(StakingPoolFactory.address, "StakingPoolFactory");
    console.log('\x1b[36m%s\x1b[0m', "StakingPoolFactory updated", StakingPoolFactory.address);
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

  if(FrensMetaHelperOld == 0){
    await FrensInitialiser.setContract(FrensMetaHelper.address, "FrensMetaHelper");
    console.log('\x1b[33m%s\x1b[0m', "FrensMetaHelper initialised", FrensMetaHelper.address);
  } else if(FrensMetaHelperOld.address != FrensMetaHelper.address){
    await FrensInitialiser.deleteContract(FrensMetaHelperOld.address, "FrensMetaHelper");
    await FrensInitialiser.setContract(FrensMetaHelper.address, "FrensMetaHelper");
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

  if(FrensPoolShareTokenURIOld == 0){
    await FrensInitialiser.setContract(FrensPoolShareTokenURI.address, "FrensPoolShareTokenURI");
    console.log('\x1b[33m%s\x1b[0m', "FrensPoolShareTokenURI initialised", FrensPoolShareTokenURI.address);
  } else if(FrensPoolShareTokenURIOld.address != FrensPoolShareTokenURI.address){
    await FrensInitialiser.deleteContract(FrensPoolShareTokenURIOld.address, "FrensPoolShareTokenURI");
    await FrensInitialiser.setContract(FrensPoolShareTokenURI.address, "FrensPoolShareTokenURI");
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

  if(FrensArtOld == 0){
    await FrensInitialiser.setContract(FrensArt.address, "FrensArt");
    console.log('\x1b[33m%s\x1b[0m', "FrensArt initialised", FrensArt.address);
  } else if(FrensArtOld.address != FrensArt.address){
    await FrensInitialiser.deleteContract(FrensArtOld.address, "FrensArt");
    await FrensInitialiser.setContract(FrensArt.address, "FrensArt");
    console.log('\x1b[36m%s\x1b[0m', "FrensArt updated", FrensArt.address);
  }

  //deploying a pool for verification purposes only (is this necessary?)
    await deploy("StakingPool", {
      // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
      from: deployer,
      args: [
        "0x521B2cE927FD6d0D473789Bd3c70B296BBce613e",
        FrensStorage.address
      ],
      log: true,
      waitConfirmations: 5,
    });



};
module.exports.tags = ["FrensPoolShare", "StakingPoolFactory", "StakingPool", "FrensStorage", "FrensInitialiser", "FrensPoolShareTokenURI"];
