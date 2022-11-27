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

  const StakingPoolFactory = await ethers.getContract("StakingPoolFactory", deployer);

  await deploy("FrensPoolShare", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    args: [
      //"0x00000000219ab540356cBB839Cbe05303d7705Fa", "0xb9e155e65B5c4D66df28Da8E9a0957f06F11Bc04" //mainnet (using goerli ssvRegistryAddress until there is a mainnet deployment - some features will not work on mainnet fork)
      StakingPoolFactory.address, "0xb9e155e65B5c4D66df28Da8E9a0957f06F11Bc04" //goerli
     ],
    log: true,
    waitConfirmations: 5,
  });

  // Getting a previously deployed contract

  const FrensPoolShare = await ethers.getContract("FrensPoolShare", deployer);
  await StakingPoolFactory.setFrensPoolShare(FrensPoolShare.address);
  await StakingPoolFactory.transferOwnership("0xa53A6fE2d8Ad977aD926C485343Ba39f32D3A3F6");
  await FrensPoolShare.transferOwnership("0xa53A6fE2d8Ad977aD926C485343Ba39f32D3A3F6");



    //const stakingPool = await ethers.getContractAt('StakingPool', "0xaAC799eC2d00C013f1F11c37E654e59B0429DF6A") //<-- if you want to instantiate a version of a contract at a specific address!


  /*
  //If you want to send value to an address from the deployer
  const deployerWallet = ethers.provider.getSigner()
  await deployerWallet.sendTransaction({
    to: "0x34aA3F359A9D614239015126635CE7732c18fDF3",
    value: ethers.utils.parseEther("0.001")
  })
  */

  /*
  //If you want to send some ETH to a contract on deploy (make your constructor payable!)
  const stakingPool = await deploy("StakingPool", [], {
  value: ethers.utils.parseEther("0.05")
  });
  */

  /*
  //If you want to link a library into your contract:
  // reference: https://github.com/austintgriffith/scaffold-eth/blob/using-libraries-example/packages/hardhat/scripts/deploy.js#L19
  const stakingPool = await deploy("StakingPool", [], {}, {
   LibraryName: **LibraryAddress**
  });
  */

  // Verify from the command line by running `yarn verify`

  // You can also Verify your contracts with Etherscan here...
  // You don't want to verify on localhost
/*try {
     if (chainId !== localChainId) {
       await run("verify:verify", {
         address: StakingPool.address,
         contract: "contracts/StakingPool.sol:StakingPool",
         contractArguments: [],
       });
     }
   } catch (error) {
     console.error(error);
   }*/
};
module.exports.tags = ["FrensPoolShare"];
