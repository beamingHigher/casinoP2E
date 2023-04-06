// SPDX-License-Identifier: MIT

// IGem.sol -- Part of Supraorbs Casino
// Copyright (c) 2021 WSCF Global, Inc. <https://wscf.io>

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../lib/ERC721.sol";

interface IGem is IERC721 {
  event ChargedStateSet(address indexed chargedState);
  event ChargedSettingsSet(address indexed chargedSettings);
  event ChargedParticlesSet(address indexed chargedParticles);
  event PausedStateSet(bool isPaused);
  event SupraorbsCasinoSet(address indexed supraorbsCasino);
  event SalePriceSet(uint256 indexed tokenId, uint256 salePrice);
  event GemCreated(uint256 indexed tokenId, address indexed receiver, address creator, uint256 gemChips);
  event GemReleaseTimeLock(address indexed contractAddress, uint256 indexed tokenId, address indexed operator, uint256 unlockBlock);

  /***********************************|
  |              Public               |
  |__________________________________*/

  function creatorOf(uint256 tokenId) external view returns (address);

  function getCasinoChipsBalance(uint256 tokenId, string calldata walletManagerId, address assetToken) external returns (uint256);

  function mintGem(
    address creator,
    address receiver,
    string memory tokenMetaUri,
    string memory walletManagerId,
    address assetToken,
    uint256 assetAmount
  ) external returns (uint256 newTokenId);

  /***********************************|
  |     Only Token Creator/Owner      |
  |__________________________________*/

  function addCasinoCoins(
    uint256 tokenId,
    string calldata walletManagerId, 
    address assetToken, 
    uint256 assetAmount) 
    external returns (uint256 yieldTokensAmount);
  function withdrawCasinoCoins(
    address receiver,
    uint256 tokenId,
    string calldata walletManagerId,
    address assetToken,
    uint256 assetAmount) 
    external returns (uint256 creatorAmount, uint256 receiverAmount);
  function setReleaseTimeLock(uint256 tokenId, uint256 unlockBlock) external;
}