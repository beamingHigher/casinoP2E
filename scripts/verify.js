#!/usr/bin/env node
const hardhat = require('hardhat');
const util = require('util');
const exec = util.promisify(require('child_process').exec);
const chalk = require('chalk');

const info = (msg) => console.log(chalk.dim(msg));
const success = (msg) => console.log(chalk.green(msg));

const verifyContract = async (name, network, addressOverride = null) => {
  try {
    const deployment = (await deployments.get(name)) || {};
    const address = addressOverride || deployment.address;
    const constructorArgs = deployment.constructorArgs || [];
    info(`Verifying ${name} at address "${address}" ${constructorArgs ? 'with args' : ''}...`);

    await exec(`hardhat verify --network ${network} ${address} ${constructorArgs.map(String).join(' ')}`);
    success(`${name} verified!`);
  }
  catch (err) {
    if (/Contract source code already verified/.test(err.message || err)) {
      info(`${name} already verified`);
    } else {
      console.error(err);
    }
  }
}

async function run() {
  info('Verifying contracts');
  const network = await hardhat.ethers.provider.getNetwork();
  const networkName = network.name === 'homestead' ? 'mainnet' : network.name;
  info(`Verifying contracts on network "${networkName}"...`);

  // NFTs
  await verifyContract('Gem', networkName);

  // Casino
  await verifyContract('SupraorbsCasino', networkName);

  success('Done!');
};

run();
