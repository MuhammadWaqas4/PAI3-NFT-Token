// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import { Ownable2Step, Ownable } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20, IERC20, Address } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import { ERC721A, IERC721A } from "erc721a/contracts/ERC721A.sol";

import { BaseErrors } from "../interfaces/Errors.sol";
import { IBase } from "../interfaces/IBase.sol";

import { _ETH } from "../Globals.sol";

/**
 * @title Base.
 * @author PAI3 Team.
 * @notice Base NFT collection.
 */
abstract contract Base is Ownable2Step, ERC721A, BaseErrors, IBase {
    using SafeERC20 for IERC20;
    using Address for address payable;
    using Strings for string;
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /* ========== STATE VARIABLES ========== */

    /// @dev One year time in seconds.
    uint256 private constant _ONE_YEAR_TIME = 31_536_000 seconds;

    /// @inheritdoc IBase
    uint256 public immutable VESTING_EXPIRY;

    /// @inheritdoc IBase
    uint256 public immutable BASE_COST_SINGLE;

    /// @inheritdoc IBase
    address public immutable FEE_WALLET;

    /// @inheritdoc IBase
    address public signer;

    /// @inheritdoc IBase
    string public baseURI;

    /// @inheritdoc IBase
    mapping(IERC20 token => AggregatorV3Interface priceFeed) public priceFeeds;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Constructor. Assigns ownership and initializes variables.
     * @param owner_ Address of the contract owner.
     * @param name_ Token collection name.
     * @param symbol_ Token collection symbol.
     * @param baseCostSingle_ Base cost for a single NFT.
     * @param feeWallet_ Address of the fee wallet.
     * @param signer_ Address of the signatrue signer.
     * @param baseURI_ Base URI for computing the tokenURI.
     * @param tokens_ Addresses of the tokens to be registered as payment
     * tokens.
     * @param priceFeeds_ Addresses of the price feed relevant to a registered
     * payment token.
     */
    constructor(
        address owner_,
        string memory name_,
        string memory symbol_,
        uint256 baseCostSingle_,
        address feeWallet_,
        address signer_,
        string memory baseURI_,
        IERC20[] memory tokens_,
        AggregatorV3Interface[] memory priceFeeds_
    ) Ownable(owner_) ERC721A(name_, symbol_) {
        if (feeWallet_ == address(0)) {
            _revert(InvalidAddress.selector);
        }

        if (baseCostSingle_ == 0) {
            _revert(InvalidValue.selector);
        }

        uint256 length = tokens_.length;

        if (length == 0) {
            _revert(InvalidArrayLength.selector);
        }

        if (length != priceFeeds_.length) {
            _revert(InvalidArrayArity.selector);
        }

        FEE_WALLET = feeWallet_;
        VESTING_EXPIRY = block.timestamp + _ONE_YEAR_TIME;
        BASE_COST_SINGLE = baseCostSingle_;

        _updateSigner(signer_);
        _setBaseURI(baseURI_);

        for (uint256 i = 0; i < length; ++i) {
            _updatePriceFeed(tokens_[i], priceFeeds_[i]);
        }
    }

    /* ========== FUNCTIONS ========== */

    /**
     * @inheritdoc IBase
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

        payable(FEE_WALLET).sendValue(cost);

        if (msg.value > cost) {
            payable(msg.sender).sendValue(msg.value - cost);
        }

        _safeMint(msg.sender, quantity);
    }

    /**
     * @inheritdoc IBase
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

        token.safeTransferFrom(msg.sender, FEE_WALLET, cost);

        _safeMint(msg.sender, quantity);
    }

    /**
     * @inheritdoc IBase
     */
    function updateSigner(address newSigner) external onlyOwner {
        _updateSigner(newSigner);
    }

    /**
     * @inheritdoc IBase
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _setBaseURI(newBaseURI);
    }

    /**
     * @inheritdoc IBase
     */
    function updatePriceFeed(
        IERC20 token,
        AggregatorV3Interface newPriceFeed
    ) external onlyOwner {
        _updatePriceFeed(token, newPriceFeed);
    }

    /**
     * @inheritdoc ERC721A
     * @dev Overridden to add vesting check.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) {
        if (block.timestamp < VESTING_EXPIRY) {
            address sender = msg.sender;
            uint32 senderSize;
            uint32 toSize;

            assembly {
                senderSize := extcodesize(sender)
                toSize := extcodesize(to)
            }

            if (senderSize > 0 || toSize > 0) {
                _revert(BeforeVestingExpiry.selector);
            }
        }

        super.transferFrom(from, to, tokenId);
    }

    /**
     * @inheritdoc ERC721A
     * @dev Overridden to include this contracts `interfaceId`.
     * @param interfaceId Id of the required interface.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, IERC721A) returns (bool) {
        return
            interfaceId == type(IBase).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Implements {mint} logic.
     */
    function _processMint(
        IERC20 token,
        uint8 tokenDecimals,
        uint256 quantity,
        uint256 deadline,
        bytes memory signature
    ) internal virtual returns (uint256) {
        if (quantity == 0) {
            _revert(InvalidValue.selector);
        }

        uint256 baseCost = quantity * BASE_COST_SINGLE;

        AggregatorV3Interface priceFeed = priceFeeds[token];

        if (address(priceFeed) == address(0)) {
            _revert(IncorrectPaymentToken.selector);
        }

        uint256 fromTokenId = _nextTokenId();

        bytes32 hash = keccak256(
            abi.encodePacked(msg.sender, fromTokenId, deadline)
        ).toEthSignedMessageHash();

        if (signer != hash.recover(signature)) {
            _revert(IncorrectSignatureRecovery.selector);
        }

        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 normalization = priceFeed.decimals() + tokenDecimals;
        uint256 cost = (baseCost * 10 ** normalization) / uint256(price);

        if (cost < BASE_COST_SINGLE) {
            _revert(InsufficientCost.selector);
        }

        emit Mint({
            minter: msg.sender,
            token: token,
            fromTokenId: fromTokenId,
            quantity: quantity,
            cost: cost
        });

        return cost;
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
     * @dev Overridden to change {_startTokenId} to `1`.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
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
        AggregatorV3Interface newPriceFeed
    ) private {
        AggregatorV3Interface priceFeed = priceFeeds[token];

        if (
            address(token) == address(0) ||
            (address(priceFeed) == address(0) &&
                address(newPriceFeed) == address(0))
        ) {
            _revert(InvalidAddress.selector);
        }

        priceFeeds[token] = newPriceFeed;

        emit UpdatePriceFeed({
            token: token,
            newPriceFeed: newPriceFeed,
            oldPriceFeed: priceFeed
        });
    }
}
