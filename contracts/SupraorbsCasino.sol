// SPDX-License-Identifier: MIT

// Gem.sol -- Part of Supraorbs Casino
// Copyright (c) 2021 WSCF Global, Inc. <https://wscf.io>

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./interfaces/ISupraorbsCasino.sol";
import "./interfaces/IGem.sol";
import "./interfaces/IChargedState.sol";
import "./interfaces/IChargedParticles.sol";

import "./lib/Bitwise.sol";
import "./lib/TokenInfo.sol";
import "./lib/RelayRecipient.sol";
import "./lib/BlackholePrevention.sol";

contract SupraorbsCasino is ISupraorbsCasino, Ownable, RelayRecipient, BlackholePrevention
{
  using SafeMath for uint256;
  using Address for address payable;
  using TokenInfo for address;
  using Bitwise for uint32;

  enum ORBS { SlotMachine, Roullette, Baccarat }

  uint256 constant internal GEM_RELEASE_LOCK_TIME = 2024033841;
  uint16 constant internal BLOCK_TIME = 15;
  
  struct Orb {
    address createdBy;
    uint256 gemChips;
    uint256 gameChips;
  }

  struct OrbState {
    Orb slotMachine;
    Orb roullette;
    Orb baccarat;

    mapping (ORBS => bool) isPlaying;
  }

  IGem internal _gem;
  IChargedState internal _chargedState;
  IChargedParticles internal _chargedParticles;

  // State of individual NFTs (by Token UUID)
  mapping (uint256 => OrbState) internal _orbState;

  /***********************************|
  |             Public API            |
  |__________________________________*/ 


  function getSlotMachineOrb(uint256 tokenId) external view virtual override returns(
    uint256 gemChips,
    uint256 gameChips,
    bool isPlaying
  ) 
  {
    uint256 tokenUuid = address(_gem).getTokenUUID(tokenId);
    isPlaying = _orbState[tokenUuid].isPlaying[ORBS.SlotMachine];
    gemChips = _orbState[tokenUuid].slotMachine.gemChips;
    gameChips = _orbState[tokenUuid].slotMachine.gameChips;
  }

  function getRoulletteOrb(uint256 tokenId) external view virtual override returns(
    uint256 gemChips,
    uint256 gameChips,
    bool isPlaying
  ) 
  {
    uint256 tokenUuid = address(_gem).getTokenUUID(tokenId);
    isPlaying = _orbState[tokenUuid].isPlaying[ORBS.Roullette];
    gemChips = _orbState[tokenUuid].roullette.gemChips;
    gameChips = _orbState[tokenUuid].roullette.gameChips;
  }

  function getBaccaratOrb(uint256 tokenId) external view virtual override returns(
    uint256 gemChips,
    uint256 gameChips,
    bool isPlaying
  ) 
  {
    uint256 tokenUuid = address(_gem).getTokenUUID(tokenId);
    isPlaying = _orbState[tokenUuid].isPlaying[ORBS.Baccarat];
    gemChips = _orbState[tokenUuid].baccarat.gemChips;
    gameChips = _orbState[tokenUuid].baccarat.gameChips;
  }

  /***********************************|
  |      Only NFT Owner/Operator      |
  |__________________________________*/

  /// @param tokenId          The ID of the Token
  /// @param walletManagerId          Name of the NFT wallet
  /// @param chipsCoin          Asset in NFT wallet
  function enterSlotMachineOrb(
    uint256 tokenId, 
    string calldata walletManagerId,
    address chipsCoin
  )
    external
    virtual
    override
    onlyErc721OwnerOrOperator(tokenId, _msgSender())
    returns(bool isPlaying)
  {
    isPlaying = _enterSlotMachineOrb(tokenId, walletManagerId, chipsCoin);
  }

  /// @param tokenId          The ID of the Token
  /// @param walletManagerId          Name of the NFT wallet
  /// @param chipsCoin          Asset in NFT wallet
  function enterRoulletteOrb(
    uint256 tokenId, 
    string calldata walletManagerId,
    address chipsCoin
  )
    external
    virtual
    override
    onlyErc721OwnerOrOperator(tokenId, _msgSender())
    returns(bool isPlaying)
  {
    isPlaying = _enterRoulletteOrb(tokenId, walletManagerId, chipsCoin);
  }

  /// @param tokenId          The ID of the Token
  /// @param walletManagerId          Name of the NFT wallet
  /// @param chipsCoin          Asset in NFT wallet
  function enterBaccaratOrb(
    uint256 tokenId, 
    string calldata walletManagerId,
    address chipsCoin
  )
    external
    virtual
    override
    onlyErc721OwnerOrOperator(tokenId, _msgSender())
    returns(bool isPlaying)
  {
    isPlaying = _enterBaccaratOrb(tokenId, walletManagerId, chipsCoin);
  }

  /// @param tokenId          The ID of the Token
  /// @param walletManagerId          Name of the NFT wallet
  /// @param gameChips          Player's game balance
  /// @param chipsCoin          Asset in NFT wallet
  function exitSlotMachineOrb(
    uint256 tokenId, 
    string calldata walletManagerId,
    uint256 gameChips,
    address chipsCoin
  )
    external
    virtual
    override
    onlyErc721OwnerOrOperator(tokenId, _msgSender())
    returns(uint256 gemChips)
  {
    gemChips = _exitSlotMachineOrb(tokenId, walletManagerId, gameChips, chipsCoin);
  }

  /// @param tokenId          The ID of the Token
  /// @param walletManagerId          Name of the NFT wallet
  /// @param gameChips          Player's game balance
  /// @param chipsCoin          Asset in NFT wallet
  function exitRoulletteOrb(
    uint256 tokenId, 
    string calldata walletManagerId,
    uint256 gameChips,
    address chipsCoin
  )
    external
    virtual
    override
    onlyErc721OwnerOrOperator(tokenId, _msgSender())
    returns(uint256 gemChips)
  {
    gemChips = _exitRoulletteOrb(tokenId, walletManagerId, gameChips, chipsCoin);
  }

  /// @param tokenId          The ID of the Token
  /// @param walletManagerId          Name of the NFT wallet
  /// @param gameChips          Player's game balance
  /// @param chipsCoin          Asset in NFT wallet
  function exitBaccaratOrb(
    uint256 tokenId, 
    string calldata walletManagerId,
    uint256 gameChips,
    address chipsCoin
  )
    external
    virtual
    override
    onlyErc721OwnerOrOperator(tokenId, _msgSender())
    returns(uint256 gemChips)
  {
    gemChips = _exitBaccaratOrb(tokenId, walletManagerId, gameChips, chipsCoin);
  }

  /***********************************|
  |          Only Admin/DAO           |
  |      (blackhole prevention)       |
  |__________________________________*/

  function withdrawEther(address payable receiver, uint256 amount) external onlyOwner {
    _withdrawEther(receiver, amount);
  }

  function withdrawErc20(address payable receiver, address tokenAddress, uint256 amount) external onlyOwner {
    _withdrawERC20(receiver, tokenAddress, amount);
  }

  function withdrawERC721(address payable receiver, address tokenAddress, uint256 tokenId) external onlyOwner {
    _withdrawERC721(receiver, tokenAddress, tokenId);
  }


  /***********************************|
  |         Private Functions         |
  |__________________________________*/

  function _enterSlotMachineOrb(
    uint256 tokenId, 
    string calldata walletManagerId,
    address chipsCoin
  )
    internal
    virtual
    returns(bool isPlaying)
  {
    uint256 tokenUuid = address(_gem).getTokenUUID(tokenId);
    require(!_orbState[tokenUuid].isPlaying[ORBS.SlotMachine], "ORB:E-106");
    uint256 chipsBalance = _gem.getCasinoChipsBalance(tokenId, walletManagerId, chipsCoin);
    require(chipsBalance > 0, "ORB:E-107");
    _orbState[tokenUuid].slotMachine.gemChips = chipsBalance;
    _orbState[tokenUuid].slotMachine.gameChips = chipsBalance;
    _orbState[tokenUuid].slotMachine.createdBy = _msgSender();
    uint256 unlockBlock = block.number.add((GEM_RELEASE_LOCK_TIME.sub(block.timestamp)).div(BLOCK_TIME));
    //set isPlaying
    _orbState[tokenUuid].isPlaying[ORBS.SlotMachine] = true;
    _chargedState.setReleaseTimelock(address(_gem), tokenId, unlockBlock);
    //return orb state
    isPlaying = _orbState[tokenUuid].isPlaying[ORBS.SlotMachine];
    emit EnterSlotMachineOrb(_msgSender(), tokenId, chipsBalance);
  }

  function _enterRoulletteOrb(
    uint256 tokenId, 
    string calldata walletManagerId,
    address chipsCoin
  )
    internal
    virtual
    returns(bool isPlaying)
  {
    uint256 tokenUuid = address(_gem).getTokenUUID(tokenId);
    require(!_orbState[tokenUuid].isPlaying[ORBS.Roullette], "ORB:E-106");
    uint256 chipsBalance = _gem.getCasinoChipsBalance(tokenId, walletManagerId, chipsCoin);
    require(chipsBalance > 0, "ORB:E-107");
    _orbState[tokenUuid].roullette.gemChips = chipsBalance;
    _orbState[tokenUuid].roullette.gameChips = chipsBalance;
    _orbState[tokenUuid].roullette.createdBy = _msgSender();
    //set release lock on GEM _setReleaseLock
    uint256 unlockBlock = block.number.add((GEM_RELEASE_LOCK_TIME.sub(block.timestamp)).div(BLOCK_TIME));
    _chargedState.setReleaseTimelock(address(_gem), tokenId, unlockBlock);
    //set isPlaying
    _orbState[tokenUuid].isPlaying[ORBS.Roullette] = true;
    //return orb state
    isPlaying = _orbState[tokenUuid].isPlaying[ORBS.Roullette];
    emit EnterRoulletteOrb(_msgSender(), tokenId, chipsBalance);
  }

  function _enterBaccaratOrb(
    uint256 tokenId, 
    string calldata walletManagerId,
    address chipsCoin
  )
    internal
    virtual
    returns(bool isPlaying)
  {
    uint256 tokenUuid = address(_gem).getTokenUUID(tokenId);
    require(!_orbState[tokenUuid].isPlaying[ORBS.Baccarat], "ORB:E-106");
    uint256 chipsBalance = _gem.getCasinoChipsBalance(tokenId, walletManagerId, chipsCoin);
    require(chipsBalance > 0, "ORB:E-107");
    _orbState[tokenUuid].baccarat.gemChips = chipsBalance;
    _orbState[tokenUuid].baccarat.gameChips = chipsBalance;
    _orbState[tokenUuid].baccarat.createdBy = _msgSender();
    //set release lock on GEM _setReleaseLock
    uint256 unlockBlock = block.number.add((GEM_RELEASE_LOCK_TIME.sub(block.timestamp)).div(BLOCK_TIME));
    _chargedState.setReleaseTimelock(address(_gem), tokenId, unlockBlock);
    //set isPlaying
    _orbState[tokenUuid].isPlaying[ORBS.Baccarat] = true;
    //return orb state
    isPlaying = _orbState[tokenUuid].isPlaying[ORBS.Baccarat];
    emit EnterBaccaratOrb(_msgSender(), tokenId, chipsBalance);
  }

  function _exitSlotMachineOrb(
    uint256 tokenId,
    string calldata walletManagerId,
    uint256 gameChips,
    address chipsCoin
  )
  internal
  virtual
  returns(uint256 gemChips)
  {
    uint256 tokenUuid = address(_gem).getTokenUUID(tokenId);
    require(_orbState[tokenUuid].isPlaying[ORBS.SlotMachine], "ORB:E-108"); //user must be playing slot
    require(_orbState[tokenUuid].slotMachine.createdBy == _msgSender(), "ORB:E-109");
    _orbState[tokenUuid].slotMachine.gameChips = gameChips;
    uint256 chipsBalance = _gem.getCasinoChipsBalance(tokenId, walletManagerId, chipsCoin);
    if (_orbState[tokenUuid].slotMachine.gemChips < chipsBalance)
    {
      _orbState[tokenUuid].slotMachine.gemChips = chipsBalance;
    }
    //set release lock on GEM _setReleaseLock
    uint256 unlockBlock = 0;
    _chargedState.setReleaseTimelock(address(_gem), tokenId, unlockBlock);
    if (_orbState[tokenUuid].slotMachine.gemChips > _orbState[tokenUuid].slotMachine.gameChips)
    {
      uint256 lossChips = _orbState[tokenUuid].slotMachine.gemChips.sub(_orbState[tokenUuid].slotMachine.gameChips);
      //_gem.withdrawCasinoCoins(owner(), tokenId, walletManagerId, chipsCoin, lossChips);

      _chargedParticles.releaseParticleAmount(
        owner(),
        address(_gem),
        tokenId,
        walletManagerId,
        chipsCoin,
        lossChips
      );
    }
    else if (_orbState[tokenUuid].slotMachine.gemChips < _orbState[tokenUuid].slotMachine.gameChips)
    {
      uint256 wonChips = _orbState[tokenUuid].slotMachine.gameChips.sub(_orbState[tokenUuid].slotMachine.gemChips);
      //Collect asset token from casino admin(Set owner address Allowance of coin for Casino contract)
      _collectAssetToken(owner(), chipsCoin, wonChips);

      IERC20(chipsCoin).approve(address(_chargedParticles), wonChips);
      //_gem.addCasinoCoins(tokenId, walletManagerId, chipsCoin, wonChips); //directly calling charged partocles function

      _chargedParticles.energizeParticle(
        address(_gem),
        tokenId,
        walletManagerId,
        chipsCoin,
        wonChips,
        address(0x0)
      );
    }
    //set isPlaying
    _orbState[tokenUuid].isPlaying[ORBS.SlotMachine] = false;
    gemChips = _gem.getCasinoChipsBalance(tokenId, walletManagerId, chipsCoin);
    emit ExitSlotMachineOrb(_msgSender(), tokenId, gameChips, gemChips);
  }

  function _exitRoulletteOrb(
    uint256 tokenId,
    string calldata walletManagerId,
    uint256 gameChips,
    address chipsCoin
  )
  internal
  virtual
  returns(uint256 gemChips)
  {
    uint256 tokenUuid = address(_gem).getTokenUUID(tokenId);
    require(_orbState[tokenUuid].isPlaying[ORBS.Roullette], "ORB:E-108"); //user must be playing slot
    require(_orbState[tokenUuid].roullette.createdBy == _msgSender(), "ORB:E-109");
    _orbState[tokenUuid].roullette.gameChips = gameChips;
    uint256 chipsBalance = _gem.getCasinoChipsBalance(tokenId, walletManagerId, chipsCoin);
    if (_orbState[tokenUuid].roullette.gemChips < chipsBalance)
    {
      _orbState[tokenUuid].roullette.gemChips = chipsBalance;
    }
    //set release lock on GEM _setReleaseLock
    uint256 unlockBlock = block.number.sub(1);
    _chargedState.setReleaseTimelock(address(_gem), tokenId, unlockBlock);
    if (_orbState[tokenUuid].roullette.gemChips > _orbState[tokenUuid].roullette.gameChips)
    {
      uint256 lossChips = _orbState[tokenUuid].roullette.gemChips.sub(_orbState[tokenUuid].roullette.gameChips);
      //_gem.withdrawCasinoCoins(owner(), tokenId, walletManagerId, chipsCoin, lossChips);

      _chargedParticles.releaseParticleAmount(
        owner(),
        address(_gem),
        tokenId,
        walletManagerId,
        chipsCoin,
        lossChips
      );
    }
    else if (_orbState[tokenUuid].roullette.gemChips < _orbState[tokenUuid].roullette.gameChips)
    {
      uint256 wonChips = _orbState[tokenUuid].roullette.gameChips.sub(_orbState[tokenUuid].roullette.gemChips);
      //Collect asset token from casino admin
      _collectAssetToken(owner(), chipsCoin, wonChips);

      IERC20(chipsCoin).approve(address(_chargedParticles), wonChips);
      //_gem.addCasinoCoins(tokenId, walletManagerId, chipsCoin, wonChips); //directly calling charged partocles function

      _chargedParticles.energizeParticle(
        address(_gem),
        tokenId,
        walletManagerId,
        chipsCoin,
        wonChips,
        address(0x0)
      );
    }
    //set isPlaying
    _orbState[tokenUuid].isPlaying[ORBS.Roullette] = false;
    gemChips = _gem.getCasinoChipsBalance(tokenId, walletManagerId, chipsCoin);
    emit ExitRoulletteOrb(_msgSender(), tokenId, gameChips, gemChips);
  }

  function _exitBaccaratOrb(
    uint256 tokenId,
    string calldata walletManagerId,
    uint256 gameChips,
    address chipsCoin
  )
  internal
  virtual
  returns(uint256 gemChips)
  {
    uint256 tokenUuid = address(_gem).getTokenUUID(tokenId);
    require(_orbState[tokenUuid].isPlaying[ORBS.Baccarat], "ORB:E-108"); //user must be playing slot
    require(_orbState[tokenUuid].baccarat.createdBy == _msgSender(), "ORB:E-109");
    _orbState[tokenUuid].baccarat.gameChips = gameChips;
    uint256 chipsBalance = _gem.getCasinoChipsBalance(tokenId, walletManagerId, chipsCoin);
    if (_orbState[tokenUuid].baccarat.gemChips < chipsBalance)
    {
      _orbState[tokenUuid].baccarat.gemChips = chipsBalance;
    }
    //set release lock on GEM _setReleaseLock
    uint256 unlockBlock = block.number.sub(1);
    _chargedState.setReleaseTimelock(address(_gem), tokenId, unlockBlock);
    if (_orbState[tokenUuid].baccarat.gemChips > _orbState[tokenUuid].baccarat.gameChips)
    {
      uint256 lossChips = _orbState[tokenUuid].baccarat.gemChips.sub(_orbState[tokenUuid].baccarat.gameChips);
      //_gem.withdrawCasinoCoins(owner(), tokenId, walletManagerId, chipsCoin, lossChips);

      _chargedParticles.releaseParticleAmount(
        owner(),
        address(_gem),
        tokenId,
        walletManagerId,
        chipsCoin,
        lossChips
      );
    }
    else if (_orbState[tokenUuid].baccarat.gemChips < _orbState[tokenUuid].baccarat.gameChips)
    {
      uint256 wonChips = _orbState[tokenUuid].baccarat.gameChips.sub(_orbState[tokenUuid].baccarat.gemChips);
      //Collect asset token from casino admin
      _collectAssetToken(owner(), chipsCoin, wonChips);

      IERC20(chipsCoin).approve(address(_chargedParticles), wonChips);
      //_gem.addCasinoCoins(tokenId, walletManagerId, chipsCoin, wonChips); //directly calling charged partocles function

      _chargedParticles.energizeParticle(
        address(_gem),
        tokenId,
        walletManagerId,
        chipsCoin,
        wonChips,
        address(0x0)
      );
    }
    //set isPlaying
    _orbState[tokenUuid].isPlaying[ORBS.Baccarat] = false;
    gemChips = _gem.getCasinoChipsBalance(tokenId, walletManagerId, chipsCoin);
    emit ExitBaccaratOrb(_msgSender(), tokenId, gameChips, gemChips);
  }

  /**
    * @dev Collects the Required Asset Token from the users wallet
    * @param from         The owner address to collect the Assets from
    * @param assetAmount  The Amount of Asset Tokens to Collect
    */
  function _collectAssetToken(address from, address assetToken, uint256 assetAmount) internal virtual {
    uint256 _userAssetBalance = IERC20(assetToken).balanceOf(from);
    require(assetAmount <= _userAssetBalance, "ORB:E-411");
    // Be sure to Approve this Contract to transfer your Asset Token
    require(IERC20(assetToken).transferFrom(from, address(this), assetAmount), "ORB:E-401");
  }

  /***********************************|
  | Only Admin/DAO (Supraorbs Casino) |
  |__________________________________*/
/*
  function setSlotMachineOrbChips(
    uint256 tokenId, 
    uint256 gameChips
  ) external virtual onlyOwner
  returns (uint256 gemGamechips)
  {
    uint256 tokenUuid = address(_gem).getTokenUUID(tokenId);
    require(_orbState[tokenUuid].isPlaying[ORBS.SlotMachine], "ORB:E-108"); //user must be playing slot
    _orbState[tokenUuid].slotMachine.gameChips = gameChips;
    gemGamechips = _orbState[tokenUuid].slotMachine.gameChips;
    emit SlotMachineOrbUpdated(tokenId, gemGamechips);
  }

  function setRoulletteOrbChips(
    uint256 tokenId, 
    uint256 gameChips
  ) external virtual onlyOwner 
  returns (uint256 gemGamechips)
  {
    uint256 tokenUuid = address(_gem).getTokenUUID(tokenId);
    require(_orbState[tokenUuid].isPlaying[ORBS.Roullette], "ORB:E-108"); //user must be playing slot
    _orbState[tokenUuid].roullette.gameChips = gameChips;
    gemGamechips = _orbState[tokenUuid].roullette.gameChips;
    emit RoulletteOrbUpdated(tokenId, gemGamechips);
  }

  function setbaccaratOrbChips(
    uint256 tokenId, 
    uint256 gameChips
  ) external virtual onlyOwner 
  returns (uint256 gemGamechips)
  {
    uint256 tokenUuid = address(_gem).getTokenUUID(tokenId);
    require(_orbState[tokenUuid].isPlaying[ORBS.Baccarat], "ORB:E-108"); //user must be playing slot
    _orbState[tokenUuid].baccarat.gameChips = gameChips;
    gemGamechips = _orbState[tokenUuid].baccarat.gameChips;
    emit BaccaratOrbUpdated(tokenId, gemGamechips);
  }
  */
  /**
    * @dev Setup the Gem Interface
    */
  function setGem(address gem) external virtual onlyOwner {
    _gem = IGem(gem);
    emit GemSet(gem);
  }

  /// @dev Setup the Charged-State Controller
  function setChargedState(address stateController) external virtual onlyOwner {
    _chargedState = IChargedState(stateController);
    emit ChargedStateSet(stateController);
  }

  /**
    * @dev Setup the ChargedParticles Interface
    */
  function setChargedParticles(address chargedParticles) external virtual onlyOwner {
    _chargedParticles = IChargedParticles(chargedParticles);
    emit ChargedParticlesSet(chargedParticles);
  }


  /***********************************|
  |          GSN/MetaTx Relay         |
  |__________________________________*/

  /// @dev See {BaseRelayRecipient-_msgSender}.
  function _msgSender()
    internal
    view
    virtual
    override(BaseRelayRecipient, Context)
    returns (address payable)
  {
    return BaseRelayRecipient._msgSender();
  }

  /// @dev See {BaseRelayRecipient-_msgData}.
  function _msgData()
    internal
    view
    virtual
    override(BaseRelayRecipient, Context)
    returns (bytes memory)
  {
    return BaseRelayRecipient._msgData();
  }


  /***********************************|
  |             Modifiers             |
  |__________________________________*/

  modifier onlyErc721OwnerOrOperator(uint256 tokenId, address sender) {
    require(address(_gem).isErc721OwnerOrOperator(tokenId, sender), "ORB:E-105");
    _;
  }
}
