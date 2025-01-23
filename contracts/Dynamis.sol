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

    /// @dev One year time in seconds.
    uint256 private constant _ONE_YEAR_TIME = 31_536_000 seconds;

    /// @inheritdoc IDynamis
    uint64 public constant VESTING_DURATION = 31_536_000 seconds;

    /// @dev Cap on the number of minted NFTs initially.
    /// NOTE: Once this cap is reached further minting will be paused until the
    /// next phase.
    uint256 private immutable _INITIAL_CAP;

    /// @dev Cap on the number of minted NFTs.
    /// NOTE: This value is inclusive of {_INITIAL_CAP}.
    uint256 private immutable _CAP;

    /// @inheritdoc IDynamis
    uint64 public immutable REWARD_DURATION;

    /// @inheritdoc IDynamis
    uint256 public immutable REWARD_PER_SECOND;

    /// @inheritdoc IDynamis
    uint256 public immutable BASE_COST_SINGLE;

    /// @inheritdoc IDynamis
    IERC20 public immutable PAI3;

    /// @inheritdoc IDynamis
    address public immutable TREASURY_WALLET;

    /// @inheritdoc IDynamis
    address public immutable REWARD_WALLET;

    /// @inheritdoc IDynamis
    address public signer;

    /// @inheritdoc IDynamis
    string public baseURI;

    /// @inheritdoc IDynamis
    Phase public phase;

    /// @dev Time based `records` relevant to a packed `index`.
    mapping(uint24 index => Record record) private _records;

    /// @inheritdoc IDynamis
    mapping(address account => uint256 due) public dues;

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
        if (
            params_.initialCap == 0 ||
            params_.cap == 0 ||
            params_.rewardDuration == 0 ||
            params_.rewardPerSecond == 0 ||
            params_.baseCostSingle == 0
        ) {
            _revert(InvalidAmount.selector);
        }

        if (
            params_.treasuryWallet == address(0) ||
            params_.rewardWallet == address(0)
        ) {
            _revert(InvalidAddress.selector);
        }

        if (params_.initialCap >= params_.cap) {
            _revert(InvalidInitialCap.selector);
        }

        if (params_.cap > type(uint24).max) {
            _revert(InvalidCap.selector);
        }

        uint256 length = params_.tokens.length;

        if (length == 0) {
            _revert(InvalidArrayLength.selector);
        }

        if (length != params_.priceFeeds.length) {
            _revert(InvalidArrayArity.selector);
        }

        _INITIAL_CAP = params_.initialCap;
        _CAP = params_.cap;

        REWARD_DURATION = params_.rewardDuration;
        REWARD_PER_SECOND = params_.rewardPerSecond;
        BASE_COST_SINGLE = params_.baseCostSingle;

        PAI3 = params_.pai3;
        TREASURY_WALLET = params_.treasuryWallet;
        REWARD_WALLET = params_.rewardWallet;

        _updateSigner(params_.signer);
        _setBaseURI(params_.baseURI);

        for (uint256 i = 0; i < length; ++i) {
            _updatePriceFeed(params_.tokens[i], params_.priceFeeds[i]);
        }
    }

    /* ========================== FUNCTIONS ========================== */

    /**
     * @inheritdoc IDynamis
     */
    function mintWithETH(
        uint256 quantity,
        uint256 deadline,
        bytes memory signature
    ) external payable {
        if (block.timestamp > deadline) {
            _revert(AfterSignatureDeadline.selector);
        }

        if (msg.value == 0) {
            _revert(InvalidPayableValue.selector);
        }

        IERC20 token = _ETH;
        uint8 tokenDecimals = 18;
        uint256 cost = _processMint(
            token,
            tokenDecimals,
            quantity,
            deadline,
            signature
        );

        payable(TREASURY_WALLET).sendValue(cost);

        if (msg.value > cost) {
            payable(msg.sender).sendValue(msg.value - cost);
        }

        _safeMint(msg.sender, quantity);
    }

    /**
     * @inheritdoc IDynamis
     */
    function mint(
        IERC20 token,
        uint256 quantity,
        uint256 deadline,
        bytes memory signature
    ) external {
        if (address(token) == address(0)) {
            _revert(InvalidAddress.selector);
        }

        uint8 tokenDecimals = IERC20Metadata(address(token)).decimals();
        uint256 cost = _processMint(
            token,
            tokenDecimals,
            quantity,
            deadline,
            signature
        );

        token.safeTransferFrom(msg.sender, TREASURY_WALLET, cost);

        _safeMint(msg.sender, quantity);
    }

    /**
     * @inheritdoc IDynamis
     */
    function claim(uint256 tokenId) external {
        if (ownerOf(tokenId) != msg.sender) {
            _revert(CallerNotOwner.selector);
        }

        uint256 due = dues[msg.sender];
        delete dues[msg.sender];

        Record memory record = _tokenRecords(tokenId);

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

            uint64 currentTime = uint64(
                block.timestamp < record.rewardingEndTimestamp
                    ? block.timestamp
                    : record.rewardingEndTimestamp
            );
            currentRecord.lastInteractedTimestamp = currentTime;

            reward =
                (currentTime - lastInteractedTimestamp) *
                REWARD_PER_SECOND;
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
     * @inheritdoc IDynamis
     */
    function bumpPhase() external onlyOwner {
        if (phase != Phase.FIRST) {
            _revert(AlreadyBumpedPhase.selector);
        }

        _unpause();
        phase = Phase.SECOND;
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
    function tokenRecords(
        uint256 tokenId
    ) external view returns (Record memory) {
        return _tokenRecords(tokenId);
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
        Record memory record = _tokenRecords(tokenId);

        super.transferFrom(from, to, tokenId);

        if (block.timestamp < record.vestingEndTimestamp) {
            uint32 callerSize;
            uint32 toSize;

            assembly {
                callerSize := extcodesize(caller())
                toSize := extcodesize(to)
            }

            if (callerSize > 0 || toSize > 0) {
                _revert(BeforeVestingExpiry.selector);
            }
        }

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

            uint64 currentTime = uint64(
                block.timestamp < record.rewardingEndTimestamp
                    ? block.timestamp
                    : record.rewardingEndTimestamp
            );
            currentRecord.lastInteractedTimestamp = currentTime;

            dues[from] +=
                (currentTime - lastInteractedTimestamp) *
                REWARD_PER_SECOND;
        }
    }

    /**
     * @inheritdoc IDynamis
     */
    function cap() public view returns (uint256) {
        return phase == Phase.FIRST ? _INITIAL_CAP : _CAP;
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
     * @dev Overridden to introduce {cap} to collection's {totalSupply} and to
     * add extraData for book keeping.
     */
    function _mint(address to, uint256 quantity) internal override {
        uint256 startTokenId = _nextTokenId();

        super._mint(to, quantity);

        uint256 maxSupply = cap();
        uint256 supply = totalSupply();

        if (supply > maxSupply) {
            _revert(ExceededCap.selector);
        }

        if (supply == maxSupply && phase == Phase.FIRST) {
            _pause();
        }

        uint24 startIndex = uint24(startTokenId);
        uint64 currentTimestamp = uint64(block.timestamp);

        _records[startIndex] = Record({
            startTimestamp: currentTimestamp,
            vestingEndTimestamp: currentTimestamp + VESTING_DURATION,
            rewardingEndTimestamp: currentTimestamp + REWARD_DURATION,
            lastInteractedTimestamp: currentTimestamp
        });

        _setExtraDataAt(startTokenId, startIndex);
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
     * @dev Implements {mint} logic.
     * NOTE: Can only be called when unpaused.
     */
    function _processMint(
        IERC20 token,
        uint8 tokenDecimals,
        uint256 quantity,
        uint256 deadline,
        bytes memory signature
    ) private whenNotPaused returns (uint256) {
        AggregatorV3Interface priceFeed = priceFeeds[token];

        if (address(priceFeed) == address(0)) {
            _revert(IncorrectPaymentToken.selector);
        }

        uint256 startTokenId = _nextTokenId();

        bytes32 hash = keccak256(
            abi.encodePacked(msg.sender, startTokenId, deadline)
        ).toEthSignedMessageHash();

        if (signer != hash.recover(signature)) {
            _revert(IncorrectSignatureRecovery.selector);
        }

        uint256 baseCost = quantity * BASE_COST_SINGLE;
        uint256 normalization = priceFeed.decimals() + tokenDecimals;
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 cost = (baseCost * 10 ** normalization) / uint256(price);

        if (cost < BASE_COST_SINGLE) {
            _revert(InsufficientCost.selector);
        }

        emit Mint({
            minter: msg.sender,
            token: token,
            startTokenId: startTokenId,
            quantity: quantity,
            cost: cost
        });

        return cost;
    }

    /**
     * @dev Implements {updateSigner} logic.
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

    /**
     * @dev Implements {tokenRecords} logic.
     */
    function _tokenRecords(
        uint256 tokenId
    ) private view returns (Record memory) {
        return _records[_ownershipOf(tokenId).extraData];
    }
}
