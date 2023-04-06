const {
  getDeployData,
} = require('../js-helpers/deploy');

const {
  log,
  chainNameById,
  chainIdByName,
} = require('../js-helpers/utils');

const _ = require('lodash');


module.exports = async (hre) => {
  const { ethers, getNamedAccounts } = hre;
  const { deployer, protocolOwner, trustedForwarder } = await getNamedAccounts();
  const network = await hre.network;

  const chainId = chainIdByName(network.name);
  const alchemyTimeout = chainId === 31337 ? 0 : (chainId === 1 ? 10 : 7);

  const executeTx = async (txId, txDesc, callback, increaseDelay = 0) => {
    try {
      if (txId === '1-a') {
        log(`\n`);
      }
      await log(`  - [TX-${txId}] ${txDesc}`)(alchemyTimeout + increaseDelay);
      await callback();
    }
    catch (err) {
      log(`  - Transaction ${txId} Failed: ${err}`);
      log(`  - Retrying;`);
      await executeTx(txId, txDesc, callback, 3);
    }
  }

  const ddSupraorbsCasino = getDeployData('SupraorbsCasino', chainId);
  const ddGem = getDeployData('Gem', chainId);
  const chargedStateAddress = '0x298cb5798c0F0af4850d1a380E28E25C02FF087A';
  const chargedSettingsAddress = '0x47563186A46Aa3EBbEA5D294c8514f0ED49f2e2c';
  const chargedParticlesAddress = '0x3A9891279481bB968a8d1300C40d9279111f1CDA';

  log('\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
  log('Supraorbs Casino - Contract Initialization');
  log('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n');

  log('  Using Network: ', chainNameById(chainId));
  log('  Using Accounts:');
  log('  - Deployer:          ', deployer);
  log('  - Owner:             ', protocolOwner);
  log('  - Trusted Forwarder: ', trustedForwarder);
  log(' ');

  log('  Loading Supraorbs Casino from: ', ddSupraorbsCasino.address);
  const SupraorbsCasino = await ethers.getContractFactory('SupraorbsCasino');
  const supraorbsCasino = await SupraorbsCasino.attach(ddSupraorbsCasino.address);

  log('  Loading Gem from: ', ddGem.address);
  const Gem = await ethers.getContractFactory('Gem');
  const gem = await Gem.attach(ddGem.address);


  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // 1. Setup Supraorbs Casino
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  await executeTx('1-a', 'Supraorbs Casino: Registering Gem at: ' + ddGem.address, async () =>
    await supraorbsCasino.setGem(ddGem.address)
  );


  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // 2. Setup Gem
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  await executeTx('2-b', 'Gem: Registering ChargedState', async () =>
    await gem.setChargedState(chargedStateAddress)
  );

  await executeTx('2-c', 'Gem: Registering ChargedSettings', async () =>
    await gem.setChargedSettings(chargedSettingsAddress)
  );

  await executeTx('2-d', 'Gem: Registering ChargedParticles', async () =>
    await gem.setChargedParticles(chargedParticlesAddress)
  );

  //Get Approval for Gem NFT from charged particles team


  log(`\n  Contract Initialization Complete!`);
  log('\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n');
};

module.exports.tags = ['setup'];
