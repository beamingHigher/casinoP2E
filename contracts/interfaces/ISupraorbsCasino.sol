// SPDX-License-Identifier: MIT

// Gem.sol -- Part of Supraorbs Casino
// Copyright (c) 2021 WSCF Global, Inc. <https://wscf.io>

pragma solidity 0.6.12;

/**
 * @notice Interface for Supraorbs Casino
 */
interface ISupraorbsCasino {
  event EnterSlotMachineOrb(address indexed player, uint256 indexed tokenId, uint256 gemChips);
  event EnterRoulletteOrb(address indexed player, uint256 indexed tokenId, uint256 gemChips);
  event EnterBaccaratOrb(address indexed player, uint256 indexed tokenId, uint256 gemChips);
  event ExitSlotMachineOrb(address indexed player, uint256 indexed tokenId, uint256 gameChips, uint256 gemChips);
  event ExitRoulletteOrb(address indexed player, uint256 indexed tokenId, uint256 gameChips, uint256 gemChips);
  event ExitBaccaratOrb(address indexed player, uint256 indexed tokenId, uint256 gameChips, uint256 gemChips);
  event SlotMachineOrbUpdated(uint256 indexed tokenId, uint256 gemGameChips);
  event RoulletteOrbUpdated(uint256 indexed tokenId, uint256 gemGameChips);
  event BaccaratOrbUpdated(uint256 indexed tokenId, uint256 gemGameChips);
  event GemSet(address indexed settings);
  event ChargedStateSet(address indexed settings);
  event ChargedParticlesSet(address indexed chargedParticles);

  /***********************************|
  |             Public API            |
  |__________________________________*/

  function getSlotMachineOrb(uint256 tokenId) external view returns(uint256 gemChips, uint256 gameChips, bool isPlaying);
  function getRoulletteOrb(uint256 tokenId) external view returns(uint256 gemChips, uint256 gameChips, bool isPlaying);
  function getBaccaratOrb(uint256 tokenId) external view returns(uint256 gemChips, uint256 gameChips, bool isPlaying);

  /***********************************|
  |     Only Token Creator/Owner      |
  |__________________________________*/

  function enterSlotMachineOrb(uint256 tokenId, string calldata walletManagerId, address chipsCoin) external returns(bool isPlaying);
  function enterRoulletteOrb(uint256 tokenId, string calldata walletManagerId, address chipsCoin) external returns(bool isPlaying);
  function enterBaccaratOrb(uint256 tokenId, string calldata walletManagerId, address chipsCoin) external returns(bool isPlaying);
  function exitSlotMachineOrb(uint256 tokenId, string calldata walletManagerId, uint256 gameChips, address chipsCoin) external returns(uint256 gemChips);
  function exitRoulletteOrb(uint256 tokenId, string calldata walletManagerId, uint256 gameChips, address chipsCoin) external returns(uint256 gemChips);
  function exitBaccaratOrb(uint256 tokenId, string calldata walletManagerId, uint256 gameChips, address chipsCoin) external returns(uint256 gemChips);
}
