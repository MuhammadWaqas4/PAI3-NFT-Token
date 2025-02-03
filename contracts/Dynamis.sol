// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import { Ownable2Step, Ownable } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import { ERC721A, IERC721A } from "erc721a/contracts/ERC721A.sol";

import { DynamisErrors } from "./interfaces/Errors.sol";
import { IDynamis } from "./interfaces/IDynamis.sol";

import { _ETH } from "./utils/Globals.sol";

/**
 * @title Dynamis.
 * @author PAI3 Team.
 * @notice Dynamis NFT collection.
 */
contract Dynamis is Ownable2Step, Pausable, ERC721A, DynamisErrors, IDynamis {
    using SafeERC20 for IERC20;
    using Address for address payable;
    using Strings for string;
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /* ========================== STATE VARIABLES ========================== */

    /// @dev Minimum mint quantity for the premint phase.
    uint64 private constant _SALE_MINIMUM_MINT_QUANTITY = 200;

    /// @inheritdoc IDynamis
    uint64 public constant VESTING_DURATION = 31_536_000 seconds;

    /// @inheritdoc IDynamis
    uint64 public constant REWARD_DURATION = 94_608_000 seconds;

    /// @inheritdoc IDynamis
    uint256 public constant REWARD_PER_SECOND = 0.000015854895991883 * 1e18;

    /// @inheritdoc IDynamis
    uint64 public immutable RESERVED_CAP;

    /// @inheritdoc IDynamis
    uint64 public immutable CAP;

    /// @inheritdoc IDynamis
    IERC20 public immutable PAI3;

    /// @inheritdoc IDynamis
    address public immutable TREASURY_WALLET;

    /// @inheritdoc IDynamis
    address public immutable REWARD_WALLET;

    /// @dev Current running phase.
    Phase private _phase;

    /// @inheritdoc IDynamis
    uint256 public reservedMinted;

    /// @inheritdoc IDynamis
    address public signer;

    /// @inheritdoc IDynamis
    string public baseURI;

    /// @inheritdoc IDynamis
    uint256[7] public phaseBaseCosts;

    /// @inheritdoc IDynamis
    Timestamps[7] public phaseTimestamps;

    /// @dev Denotes if a `signature` has already been `seen` at least once.
    mapping(bytes signature => bool seen) private _history;

    /// @dev Time based `records` relevant to a packed `index`.
    mapping(uint24 index => Record record) private _records;

    /// @inheritdoc IDynamis
    mapping(uint256 tokenId => uint256 due) public dues;

    /// @inheritdoc IDynamis
    mapping(IERC20 token => AggregatorV3Interface priceFeed) public priceFeeds;

    /* ========================== CONSTRUCTOR ========================== */

    /**
     * @dev Constructor. Assigns ownership and initializes variables.
     * @param params_ Params necessary for contract deployment.
     */
    constructor(
        DynamisParams memory params_
    ) Ownable(params_.owner) ERC721A(params_.name, params_.symbol) {
        if (params_.reservedCap == 0 || params_.cap == 0) {
            _revert(InvalidAmount.selector);
        }

        if (
            address(params_.pai3) == address(0) ||
            params_.treasuryWallet == address(0) ||
            params_.rewardWallet == address(0)
        ) {
            _revert(InvalidAddress.selector);
        }

        uint256 tokensLength = params_.tokens.length;

        if (tokensLength == 0) {
            _revert(InvalidArrayLength.selector);
        }

        if (tokensLength != params_.priceFeeds.length) {
            _revert(InvalidArrayArity.selector);
        }

        RESERVED_CAP = params_.reservedCap;
        CAP = params_.cap;

        PAI3 = params_.pai3;
        TREASURY_WALLET = params_.treasuryWallet;
        REWARD_WALLET = params_.rewardWallet;

        phaseBaseCosts = params_.phaseBaseCosts;

        for (uint256 i; i < phaseTimestamps.length; ++i) {
            phaseTimestamps[i] = params_.phaseTimestamps[i];
        }

        _updateSigner(params_.signer);
        _setBaseURI(params_.baseURI);

        for (uint256 i; i < tokensLength; ++i) {
            _updatePriceFeed(params_.tokens[i], params_.priceFeeds[i]);
        }
    }

    /* ========================== FUNCTIONS ========================== */

    /**
     * @inheritdoc IDynamis
     */
    function safeMint(address to, uint256 quantity) external onlyOwner {
        reservedMinted += quantity;

        uint256 maxSupply = RESERVED_CAP;
        uint256 supply = reservedMinted;

        if (supply > maxSupply) {
            _revert(ExceededCap.selector);
        }

        // Minting.
        _safeMint(to, quantity);
    }

    /**
     * @inheritdoc IDynamis
     */
    function safeMintSale(address to, uint256 quantity) external onlyOwner {
        _processPhase(quantity);

        _finalizeMint(to, quantity);
    }

    /**
     * @inheritdoc IDynamis
     */
    function mintWhitelistWithEth(
        uint256 quantity,
        uint256 deadline,
        bytes memory signature
    ) external payable {
        _processPhase(quantity);

        _processDiscount(quantity, deadline, signature);

        _processMint({ token: _ETH, tokenDecimals: 18, quantity: quantity });
    }

    /**
     * @inheritdoc IDynamis
     */
    function mintWhitelist(
        IERC20 token,
        uint256 quantity,
        uint256 deadline,
        bytes memory signature
    ) external {
        if (address(token) == address(0)) {
            _revert(InvalidAddress.selector);
        }

        _processPhase(quantity);

        _processDiscount(quantity, deadline, signature);

        _processMint({
            token: token,
            tokenDecimals: IERC20Metadata(address(token)).decimals(),
            quantity: quantity
        });
    }

    /**
     * @inheritdoc IDynamis
     */
    function mintWithEth(uint256 quantity) external payable {
        _processPhase(quantity);

        _processMint({ token: _ETH, tokenDecimals: 18, quantity: quantity });
    }

    /**
     * @inheritdoc IDynamis
     */
    function mint(IERC20 token, uint256 quantity) external {
        if (address(token) == address(0)) {
            _revert(InvalidAddress.selector);
        }

        _processPhase(quantity);

        _processMint({
            token: token,
            tokenDecimals: IERC20Metadata(address(token)).decimals(),
            quantity: quantity
        });
    }

    /**
     * @inheritdoc IDynamis
     */
    function claim(
        uint256 tokenId,
        uint256 deadline,
        bytes memory signature
    ) external {
        if (ownerOf(tokenId) != msg.sender) {
            _revert(CallerNotOwner.selector);
        }

        if (block.timestamp > deadline) {
            _revert(SignatureDeadlineCrossed.selector);
        }

        if (_history[signature]) {
            _revert(SignatureAlreadySeen.selector);
        }

        _history[signature] = true;

        bytes32 hash = keccak256(
            abi.encodePacked(msg.sender, tokenId, deadline)
        ).toEthSignedMessageHash();

        if (signer != hash.recover(signature)) {
            _revert(IncorrectSignatureRecovery.selector);
        }

        uint256 due = dues[tokenId];
        delete dues[tokenId];

        Record memory record = tokenRecords(tokenId);

        uint256 reward;

        if (record.lastInteractedTimestamp < record.rewardingEndTimestamp) {
            uint24 index = uint24(tokenId);
            Record storage currentRecord = _records[index];

            uint64 lastInteractedTimestamp = currentRecord
                .lastInteractedTimestamp;

            if (lastInteractedTimestamp == 0) {
                _initializeOwnershipAt(tokenId);

                _setExtraDataAt(tokenId, index);

                _records[index] = record;
                lastInteractedTimestamp = record.startTimestamp;
            }

            uint64 timestamp = uint64(
                block.timestamp < record.rewardingEndTimestamp
                    ? block.timestamp
                    : record.rewardingEndTimestamp
            );
            currentRecord.lastInteractedTimestamp = timestamp;

            reward = (timestamp - lastInteractedTimestamp) * REWARD_PER_SECOND;
        }

        uint256 totalReward = reward + due;

        if (totalReward == 0) {
            _revert(InsufficientReward.selector);
        }

        PAI3.safeTransferFrom(REWARD_WALLET, msg.sender, totalReward);

        emit Claim({
            claimer: msg.sender,
            tokenId: tokenId,
            reward: reward,
            due: due
        });
    }

    /**
     * @inheritdoc IDynamis
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @inheritdoc IDynamis
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @inheritdoc IDynamis
     */
    function updateSigner(address newSigner) external onlyOwner {
        _updateSigner(newSigner);
    }

    /**
     * @inheritdoc IDynamis
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _setBaseURI(newBaseURI);
    }

    /**
     * @inheritdoc IDynamis
     */
    function updatePriceFeed(
        IERC20 token,
        AggregatorV3Interface newPriceFeed
    ) external onlyOwner {
        _updatePriceFeed(token, newPriceFeed);
    }

    /**
     * @inheritdoc ERC721A
     * @dev Overridden to add vesting checks and reward generation
     * prerequisites.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) {
        Record memory record = tokenRecords(tokenId);

        if (block.timestamp < record.vestingEndTimestamp) {
            _revert(Vested.selector);
        }

        // Calling parent function.
        super.transferFrom(from, to, tokenId);

        if (record.lastInteractedTimestamp < record.rewardingEndTimestamp) {
            uint24 index = uint24(tokenId);
            Record storage currentRecord = _records[index];

            uint64 lastInteractedTimestamp = currentRecord
                .lastInteractedTimestamp;

            if (lastInteractedTimestamp == 0) {
                _setExtraDataAt(tokenId, index);

                _records[index] = record;
                lastInteractedTimestamp = record.startTimestamp;
            }

            uint64 timestamp = uint64(
                block.timestamp < record.rewardingEndTimestamp
                    ? block.timestamp
                    : record.rewardingEndTimestamp
            );
            currentRecord.lastInteractedTimestamp = timestamp;

            dues[tokenId] +=
                (timestamp - lastInteractedTimestamp) *
                REWARD_PER_SECOND;
        }
    }

    /**
     * @inheritdoc IDynamis
     */
    function tokenRecords(uint256 tokenId) public view returns (Record memory) {
        return _records[_ownershipOf(tokenId).extraData];
    }

    /**
     * @inheritdoc ERC721A
     * @dev Overridden to include this contracts `interfaceId`.
     * @param interfaceId Id of the required interface.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721A, IERC721A) returns (bool) {
        return
            interfaceId == type(IDynamis).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc ERC721A
     * @dev Overridden to add extra data in token ownership for book keeping.
     */
    function _mint(address to, uint256 quantity) internal override {
        uint256 startTokenId = _nextTokenId();

        // Calling parent function.
        super._mint(to, quantity);

        uint24 startIndex = uint24(startTokenId);
        uint64 timestamp = uint64(block.timestamp);

        _setExtraDataAt(startTokenId, startIndex);

        _records[startIndex] = Record({
            startTimestamp: timestamp,
            vestingEndTimestamp: timestamp + VESTING_DURATION,
            rewardingEndTimestamp: timestamp + REWARD_DURATION,
            lastInteractedTimestamp: timestamp
        });
    }

    /**
     * @inheritdoc ERC721A
     * @dev Overridden to return {baseURI}.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @inheritdoc ERC721A
     * @dev Overridden to create empty extraData when `from` or `to` is
     * `address(0)` and to preserve `previousExtraData` when transferring.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal pure override returns (uint24) {
        if (from == address(0) || to == address(0)) {
            return 0;
        } else {
            return previousExtraData;
        }
    }

    /**
     * @inheritdoc ERC721A
     * @dev Overridden to change start tokenId to `1`.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     * @dev Implements phase validations and phase change logic.
     * @param quantity Amount of NFTs to mint.
     */
    function _processPhase(uint256 quantity) private {
        if (
            block.timestamp <= phaseTimestamps[uint8(Phase.SALE)].startTimestamp
        ) {
            _revert(LaunchNotStarted.selector);
        }

        if (
            block.timestamp > phaseTimestamps[uint8(Phase.FINAL)].endTimestamp
        ) {
            _revert(LaunchEnded.selector);
        }

        uint8 phaseIndex = uint8(_phase);
        Timestamps memory timestamps = phaseTimestamps[phaseIndex];

        if (block.timestamp > timestamps.endTimestamp) {
            uint128 previousEndTimestamp = timestamps.endTimestamp;

            for (uint256 i = phaseIndex + 1; i < phaseTimestamps.length; ++i) {
                timestamps = phaseTimestamps[i];

                if (
                    previousEndTimestamp < block.timestamp &&
                    block.timestamp <= timestamps.startTimestamp
                ) {
                    _revert(LaunchOnHold.selector);
                }

                previousEndTimestamp = timestamps.endTimestamp;

                if (
                    timestamps.startTimestamp < block.timestamp &&
                    block.timestamp <= timestamps.endTimestamp
                ) {
                    _phase = Phase(i);

                    break;
                }
            }
        }

        if (_phase == Phase.SALE && quantity < _SALE_MINIMUM_MINT_QUANTITY) {
            _revert(InsufficientSaleMintQuantity.selector);
        }
    }

    /**
     * @dev Implements discount validations.
     * @param quantity Amount of NFTs to mint.
     * @param deadline Expiration deadline for the signed message.
     * @param signature Signed message to determine correctness in the case of a
     * discount.
     */
    function _processDiscount(
        uint256 quantity,
        uint256 deadline,
        bytes memory signature
    ) private {
        if (block.timestamp > deadline) {
            _revert(SignatureDeadlineCrossed.selector);
        }

        if (_history[signature]) {
            _revert(SignatureAlreadySeen.selector);
        }

        _history[signature] = true;

        bytes32 hash = keccak256(
            abi.encodePacked(
                msg.sender,
                quantity,
                phaseBaseCosts[uint8(_phase)],
                deadline
            )
        ).toEthSignedMessageHash();

        if (signer != hash.recover(signature)) {
            _revert(IncorrectSignatureRecovery.selector);
        }
    }

    /**
     * @dev Implements mint validations and logic.
     * NOTE: Can only be called when unpaused.
     * @param token Registered payment method.
     * @param tokenDecimals Denomination of the token used as the registered
     * payment method.
     * @param quantity Amount of NFTs to mint.
     */
    function _processMint(
        IERC20 token,
        uint8 tokenDecimals,
        uint256 quantity
    ) private whenNotPaused {
        AggregatorV3Interface priceFeed = priceFeeds[token];

        if (address(priceFeed) == address(0)) {
            _revert(IncorrectPaymentToken.selector);
        }

        uint256 totalBaseCost = quantity * phaseBaseCosts[uint8(_phase)];

        uint256 normalization = priceFeed.decimals() + tokenDecimals;
        (, int256 price, , , ) = priceFeed.latestRoundData();

        uint256 cost = (totalBaseCost * 10 ** normalization) / uint256(price);

        if (cost == 0) {
            _revert(InsufficientCost.selector);
        }

        emit Mint({
            minter: msg.sender,
            token: token,
            startTokenId: _nextTokenId(),
            quantity: quantity,
            cost: cost
        });

        if (token == _ETH) {
            if (msg.value == 0) {
                _revert(InvalidPayableValue.selector);
            }

            payable(TREASURY_WALLET).sendValue(cost);

            if (msg.value > cost) {
                payable(msg.sender).sendValue(msg.value - cost);
            }
        } else {
            token.safeTransferFrom(msg.sender, TREASURY_WALLET, cost);
        }

        _finalizeMint(msg.sender, quantity);
    }

    /**
     * @dev Implements minting and cap validations.
     * @param to Address to receive the NFTS.
     * @param quantity Amount of NFTs to mint.
     */
    function _finalizeMint(address to, uint256 quantity) private {
        // Minting.
        _safeMint(to, quantity);

        uint256 maxSupply = CAP;
        uint256 supply = totalSupply() - reservedMinted;

        if (supply > maxSupply) {
            _revert(ExceededCap.selector);
        }
    }

    /**
     * @dev Implements {updateSigner} logic.
     * @param newSigner Address of the new signature signer.
     */
    function _updateSigner(address newSigner) private {
        if (newSigner == address(0)) {
            _revert(InvalidAddress.selector);
        }

        if (newSigner == signer) {
            _revert(InvalidAssignment.selector);
        }

        emit UpdateSigner({ newSigner: newSigner, oldSigner: signer });

        signer = newSigner;
    }

    /**
     * @dev Implements {setBaseUri} logic.
     * @param newBaseURI Value to set the base URI to.
     */
    function _setBaseURI(string memory newBaseURI) private {
        if (bytes(newBaseURI).length == 0) {
            _revert(InvalidString.selector);
        }

        if (newBaseURI.equal(baseURI)) {
            _revert(InvalidAssignment.selector);
        }

        emit SetBaseURI({ newBaseURI: newBaseURI, oldBaseURI: baseURI });

        baseURI = newBaseURI;
    }

    /**
     * @dev Implements {updatePriceFeed} logic.
     * @param token Address of the payment method.
     * @param priceFeed Price feed to add, remove or update for the given
     * payment method.
     */
    function _updatePriceFeed(
        IERC20 token,
        AggregatorV3Interface priceFeed
    ) private {
        AggregatorV3Interface oldPriceFeed = priceFeeds[token];

        if (
            address(token) == address(0) ||
            (address(oldPriceFeed) == address(0) &&
                address(priceFeed) == address(0))
        ) {
            _revert(InvalidAddress.selector);
        }

        priceFeeds[token] = priceFeed;

        emit UpdatePriceFeed({
            token: token,
            newPriceFeed: priceFeed,
            oldPriceFeed: oldPriceFeed
        });
    }
}
