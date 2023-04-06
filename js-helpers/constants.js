const { ethers } = require('ethers');

const weiPerEth = ethers.constants.WeiPerEther;

const CONSTANT_1K = 1000;
const CONSTANT_10K = 10 * CONSTANT_1K;
const CONSTANT_100K = 10 * CONSTANT_10K;
const CONSTANT_1M = 10 * CONSTANT_100K;

module.exports = {
  weiPerEth,
  CONSTANT_1K,
  CONSTANT_10K,
  CONSTANT_100K,
  CONSTANT_1M,
};
