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
  var FrensInitialiserOld = 0;
  var FrensStorageOld = 0;
  var StakingPoolFactoryOld = 0;

  try{
    FrensPoolShareOld = await ethers.getContract("FrensPoolShare", deployer);
    FrensInitialiserOld = await ethers.getContract("FrensInitialiser", deployer);
    FrensStorageOld = await ethers.getContract("FrensStorage", deployer);
    StakingPoolFactoryOld = await ethers.getContract("StakingPoolFactory", deployer);
  } catch(e) {

  }

  await deploy("FrensStorage", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    args: [
      //no args
     ],
    log: true,
    waitConfirmations: 5,
  });

  const FrensStorage = await ethers.getContract("FrensStorage", deployer);

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

  const StakingPoolFactory = await ethers.getContract("StakingPoolFactory", deployer);

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

  await deploy("FrensInitialiser", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    args: [  FrensStorage.address ],
    log: true,
    waitConfirmations: 5,
  });

  const FrensPoolShare = await ethers.getContract("FrensPoolShare", deployer);
  const FrensInitialiser = await ethers.getContract("FrensInitialiser", deployer);

  if(StakingPoolFactoryOld == 0) {
    await FrensInitialiser.setContract(StakingPoolFactory.address, "StakingPoolFactory");
    console.log("StakingPoolFactory initialised");
  } else if(StakingPoolFactoryOld.address != StakingPoolFactory.address){
    await FrensInitialiser.deleteContract(StakingPoolFactoryOld.address, "StakingPoolFactory");
    await FrensInitialiser.setContract(StakingPoolFactory.address, "StakingPoolFactory");
    console.log("StakingPoolFactory updated");
  }

  if(FrensPoolShareOld == 0){
    await FrensPoolShare.transferOwnership("0xa53A6fE2d8Ad977aD926C485343Ba39f32D3A3F6");
    await FrensInitialiser.setContract(FrensPoolShare.address, "FrensPoolShare");
    console.log("FrensPoolShare initialised");
  } else if(FrensPoolShareOld.address != FrensPoolShare.address){
    await FrensPoolShare.transferOwnership("0xa53A6fE2d8Ad977aD926C485343Ba39f32D3A3F6");
    await FrensInitialiser.deleteContract(FrensPoolShareOld.address, "FrensPoolShare");
    await FrensInitialiser.setContract(FrensPoolShare.address, "FrensPoolShare");
    console.log("FrensPoolShare updated");
  }

  if(FrensInitialiserOld == 0) {
    await FrensInitialiser.setContract(FrensInitialiser.address, "FrensInitialiser");
    //ssvRegistry
    await FrensInitialiser.setExternalContract("0xb9e155e65B5c4D66df28Da8E9a0957f06F11Bc04", "SSVRegistry") //goerli
    //deposit contract
    await FrensInitialiser.setExternalContract("0xff50ed3d0ec03aC01D4C79aAd74928BFF48a7b2b", "DepositContract") //goerli
    console.log("initialiser initialised");
  } else if(FrensInitialiserOld.address != FrensInitialiser.address) {
    await FrensInitialiser.deleteContract(FrensInitialiserOld.address,"FrensInitialiser");
    await FrensInitialiser.setContract(FrensInitialiser.address, "FrensInitialiser");
    console.log("initialiser updated");
  }





};
module.exports.tags = ["FrensStorage", "StakingPoolFactory", "StakingPool", "FrensStorage", "FrensInitialiser"];
