const {
  TASK_TEST,
  TASK_COMPILE_GET_COMPILER_INPUT
} = require('hardhat/builtin-tasks/task-names');

require('dotenv').config();

require('@nomiclabs/hardhat-waffle');
require('@nomiclabs/hardhat-etherscan');
require('@nomiclabs/hardhat-ethers');
require('@openzeppelin/hardhat-upgrades');
require('hardhat-gas-reporter');
require('hardhat-abi-exporter');
require('solidity-coverage');
require('hardhat-deploy-ethers');
require('hardhat-deploy');

// This must occur after hardhat-deploy!
task(TASK_COMPILE_GET_COMPILER_INPUT).setAction(async (_, __, runSuper) => {
  const input = await runSuper();
  input.settings.metadata.useLiteralContent = process.env.USE_LITERAL_CONTENT != 'false';
  console.log(`useLiteralContent: ${input.settings.metadata.useLiteralContent}`);
  return input;
});

// Task to run deployment fixtures before tests without the need of "--deploy-fixture"
//  - Required to get fixtures deployed before running Coverage Reports
task(
  TASK_TEST,
  "Runs the coverage report",
  async (args, hre, runSuper) => {
    await hre.run('compile');
    await hre.deployments.fixture();
    return runSuper({...args, noCompile: true});
  }
);

const mnemonic = {
  testnet: `${process.env.TESTNET_MNEMONIC}`.replace(/_/g, ' '),
  mainnet: `${process.env.MAINNET_MNEMONIC}`.replace(/_/g, ' '),
};

const optimizerDisabled = process.env.OPTIMIZER_DISABLED

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: '0.6.12',
    settings: {
        optimizer: {
            enabled: !optimizerDisabled,
            runs: 1
        },
        evmVersion: 'istanbul'
    },
  },
  paths: {
    sources: "./contracts",
    cache: "./cache",
    artifacts: './build/contracts',
    deploy: './deploy',
    deployments: './deployments'
  },
  networks: {
    hardhat: {
        blockGasLimit: 200000000,
        allowUnlimitedContractSize: true,
        gasPrice: 1e9,
        forking: {
            url: `https://eth-mainnet.alchemyapi.io/v2/${process.env.ALCHEMY_APIKEY}`,
            blockNumber: 11400000,  // MUST be after Aave V2 was deployed
            timeout: 1000000
        },
    },
    kovan: {
        url: `https://kovan.infura.io/v3/${process.env.INFURA_APIKEY}`,
        //url: `https://eth-kovan.alchemyapi.io/v2/${process.env.ALCHEMY_APIKEY}`,
        blockGasLimit: 12400000,
        allowUnlimitedContractSize: true,
        gasPrice: 10e9,
        accounts: {
            mnemonic: mnemonic.testnet,
            initialIndex: 0,
            count: 10,
        }
    },
    ropsten: {
      url: `https://ropsten.infura.io/v3/${process.env.INFURA_APIKEY}`,
      //url: `https://eth-kovan.alchemyapi.io/v2/${process.env.ALCHEMY_APIKEY}`,
      gasPrice: 10e9,
      blockGasLimit: 12400000,
      accounts: {
          mnemonic: mnemonic.testnet,
          initialIndex: 0,
          count: 10,
      }
    },
    maticmum: {
      url: `https://rpc-mumbai.maticvigil.com`,
      // url: `https://polygon-mumbai.infura.io/v3/${process.env.INFURA_APIKEY}`,
      gasPrice: 30000000000,
      accounts: {
          mnemonic: mnemonic.testnet,
          initialIndex: 1,
          count: 10,
      },
      chainId: 80001
  },
    mainnet: {
        url: `https://mainnet.infura.io/v3/${process.env.INFURA_APIKEY}`,
        // url: `https://eth-mainnet.alchemyapi.io/v2/${process.env.ALCHEMY_APIKEY}`,
        gasPrice: 38e9,
        blockGasLimit: 12487794,
        accounts: {
            mnemonic: mnemonic.mainnet,
            initialIndex: 0,
            count: 3,
        }
    },
  },
  etherscan: {
    apiKey: process.env.MATICSCAN_APIKEY
  },
  gasReporter: {
      currency: 'USD',
      gasPrice: 1,
      enabled: (process.env.REPORT_GAS) ? true : false
  },
  abiExporter: {
    path: './abis',
    clear: true,
    flat: true,
    only: [
      'SupraorbsCasino',
      'Gem',
      'ERC721',
    ],
  },
  namedAccounts: {
      deployer: {
        default: 0,
      },
      protocolOwner: {
        default: 0,
        0: '0xD3C3dE565fA8890293160C420ef81D5aed818408', 
      },
      initialMinter: {
        default: 2,
      },
      user1: {
        default: 3,
      },
      user2: {
        default: 4,
      },
      user3: {
        default: 5,
      },
      trustedForwarder: {
        default: 1, // Account 2
        1: '0x0C8ce8eF948b41819138a5d27c160340a7991Dbd', // mainnet
        3: '0x0C8ce8eF948b41819138a5d27c160340a7991Dbd', // ropsten
        4: '0x0C8ce8eF948b41819138a5d27c160340a7991Dbd', // rinkeby
        42: '0x0C8ce8eF948b41819138a5d27c160340a7991Dbd', // kovan
        137: '0x0C8ce8eF948b41819138a5d27c160340a7991Dbd', // Polygon L2 Mainnet
        80001: '0x0C8ce8eF948b41819138a5d27c160340a7991Dbd', // Polygon L2 Testnet - Mumbai
      }
  },
  watcher: {
    compilation: {
      tasks: ["compile"],
      files: ["./contracts"],
      verbose: true,
    }
  },
};

