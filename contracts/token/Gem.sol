// SPDX-License-Identifier: MIT

// Gem.sol -- Part of Supraorbs Casino
// Copyright (c) 2021 WSCF Global, Inc. <https://wscf.io>

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../interfaces/IGem.sol";
import "../interfaces/IChargedState.sol";
import "../interfaces/IChargedSettings.sol";
import "../interfaces/IChargedParticles.sol";

import "../lib/ERC721.sol";
import "../lib/RelayRecipient.sol";
import "../lib/BlackholePrevention.sol";

contract Gem is IGem, ERC721, Ownable, RelayRecipient, BlackholePrevention {
  using SafeMath for uint256;
  using Address for address payable;
  using Counters for Counters.Counter;

  uint256 constant internal PERCENTAGE_SCALE = 1e4;   // 10000  (100%)
  uint256 constant internal ORB_GEM_FEES = 2e3;      // 2000   (20%)

  IChargedState internal _chargedState;
  IChargedSettings internal _chargedSettings;
  IChargedParticles internal _chargedParticles;

  Counters.Counter internal _tokenIds;

  mapping (uint256 => address) internal _tokenCreator;

  bool internal _paused;


  /***********************************|
  |          Initialization           |
  |__________________________________*/

  constructor() public ERC721("Supraorbs Casino - Gem", "GEM") {}


  /***********************************|
  |              Public               |
  |__________________________________*/

  function creatorOf(uint256 tokenId) external view virtual override returns (address) {
    return _tokenCreator[tokenId];
  }

  function getCasinoChipsBalance(
    uint256 tokenId, 
    string calldata walletManagerId, 
    address assetToken
  )
    external
    virtual
    override
    returns (uint256)
  {
    return _getCasinoChipsBalance(
      tokenId,
      walletManagerId,
      assetToken
    );
  }

  function mintGem(
    address creator,
    address receiver,
    string memory tokenMetaUri,
    string memory walletManagerId,
    address assetToken,
    uint256 assetAmount
  )
    external
    virtual
    override
    whenNotPaused
    returns (uint256 newTokenId)
  {
    newTokenId = _mintGem( 
      creator,
      receiver,
      tokenMetaUri,
      walletManagerId,
      assetToken,
      assetAmount
    );
  }

  /***********************************|
  |     Only Token Creator/Owner      |
  |__________________________________*/

  function addCasinoCoins(
    uint256 tokenId, 
    string calldata walletManagerId, 
    address assetToken, 
    uint256 assetAmount
  )
    external
    virtual
    override
    whenNotPaused
    onlyTokenOwnerOrApproved(tokenId)
    returns (uint256 yieldTokensAmount)
  {
    yieldTokensAmount = _addCasinoCoins(tokenId, walletManagerId, assetToken, assetAmount);
  }

  function withdrawCasinoCoins(
    address receiver,
    uint256 tokenId,
    string calldata walletManagerId,
    address assetToken,
    uint256 assetAmount
  )
    external
    virtual
    override
    whenNotPaused
    onlyTokenOwnerOrApproved(tokenId)
    returns (uint256 creatorAmount, uint256 receiverAmount)
  {
    (creatorAmount, receiverAmount) = _withdrawCasinoCoins(receiver, tokenId, walletManagerId, assetToken, assetAmount);
  }
 
  function setReleaseTimeLock(uint256 tokenId, uint256 unlockBlock)
    external
    virtual
    override
    whenNotPaused
    onlyTokenOwnerOrApproved(tokenId)
  {
    _setReleaseTimeLock(tokenId, unlockBlock);
  }


  /***********************************|
  |          Only Admin/DAO           |
  |__________________________________*/

  function setPausedState(bool state) external virtual onlyOwner {
    _paused = state;
    emit PausedStateSet(state);
  }
  
  /**
    * @dev Setup the ChargedParticles Interface
    */
  function setChargedParticles(address chargedParticles) external virtual onlyOwner {
    _chargedParticles = IChargedParticles(chargedParticles);
    emit ChargedParticlesSet(chargedParticles);
  }

  /// @dev Setup the Charged-State Controller
  function setChargedState(address stateController) external virtual onlyOwner {
    _chargedState = IChargedState(stateController);
    emit ChargedStateSet(stateController);
  }

  /// @dev Setup the Charged-Settings Controller
  function setChargedSettings(address settings) external virtual onlyOwner {
    _chargedSettings = IChargedSettings(settings);
    emit ChargedSettingsSet(settings);
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

  function _getCasinoChipsBalance(
    uint256 tokenId,
    string calldata walletManagerId,
    address assetToken
  )
    internal
    virtual
    returns(uint256)
  {
    return _chargedParticles.baseParticleMass(address(this), tokenId, walletManagerId, assetToken);
  }

  function _setReleaseTimeLock(uint256 tokenId, uint256 unlockBlock) internal virtual {
    _chargedState.setReleaseTimelock(address(this), tokenId, unlockBlock);
    emit GemReleaseTimeLock(address(this), tokenId, _msgSender(), unlockBlock);
  }

  function _mintGem(
    address creator,
    address receiver,
    string memory tokenMetaUri,
    string memory walletManagerId,
    address assetToken,
    uint256 assetAmount
  )
    internal
    virtual
    returns (uint256 newTokenId)
  {
    require(address(_chargedParticles) != address(0x0), "ORB:E-107");

    newTokenId = _createGem(creator, receiver, tokenMetaUri);

    _collectAssetToken(_msgSender(), assetToken, assetAmount);

    //withdraw Fees for the gem
    uint256 orbCreatorFees = assetAmount.mul(ORB_GEM_FEES).div(PERCENTAGE_SCALE);
    uint256 casinoChips = assetAmount.sub(orbCreatorFees);

    IERC20(assetToken).transfer(creator, orbCreatorFees);

    IERC20(assetToken).approve(address(_chargedParticles), casinoChips);

    _chargedParticles.energizeParticle(
      address(this),
      newTokenId,
      walletManagerId,
      assetToken,
      casinoChips,
      address(0x0)
    );
  }

  function _createGem( 
    address creator,
    address receiver,
    string memory tokenMetaUri
  )
    internal
    virtual
    returns (uint256 newTokenId)
  {
    _tokenIds.increment();

    newTokenId = _tokenIds.current();
    _safeMint(receiver, newTokenId, "");
    _tokenCreator[newTokenId] = creator;

    _setTokenURI(newTokenId, tokenMetaUri);
    
    _chargedSettings.setCreatorAnnuities(
      address(this),
      newTokenId,
      creator,
      PERCENTAGE_SCALE
    );
  }

  function _addCasinoCoins(
    uint256 tokenId,
    string memory walletManagerId,
    address assetToken,
    uint256 assetAmount
  )
    internal
    virtual
    returns (uint256 yieldTokensAmount)
  {
    _collectAssetToken(_msgSender(), assetToken, assetAmount);

    IERC20(assetToken).approve(address(_chargedParticles), assetAmount);

    yieldTokensAmount = _chargedParticles.energizeParticle(
      address(this),
      tokenId,
      walletManagerId,
      assetToken,
      assetAmount,
      address(0x0)
    );
  }

  function _withdrawCasinoCoins(
    address receiver,
    uint256 tokenId,
    string calldata walletManagerId,
    address assetToken,
    uint256 assetAmount
  )
    internal
    virtual
    returns (uint256 creatorAmount, uint256 receiverAmount)
  {
    (creatorAmount, receiverAmount) = _chargedParticles.releaseParticleAmount(
      receiver,
      address(this),
      tokenId,
      walletManagerId,
      assetToken,
      assetAmount
    );
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

  function _refundOverpayment(uint256 threshold) internal virtual {
    uint256 overage = msg.value.sub(threshold);
    if (overage > 0) {
      payable(_msgSender()).sendValue(overage);
    }
  }

  function _transfer(address from, address to, uint256 tokenId) internal virtual override {
    _chargedState.setTemporaryLock(address(this), tokenId, false);
    super._transfer(from, to, tokenId);
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

  modifier whenNotPaused() {
    require(!_paused, "ORB:E-101");
    _;
  }

  modifier onlyTokenOwnerOrApproved(uint256 tokenId) {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ORB:E-105");
    _;
  }

  modifier onlyTokenCreator(uint256 tokenId) {
    require(_tokenCreator[tokenId] == _msgSender(), "ORB:E-104");
    _;
  }
}