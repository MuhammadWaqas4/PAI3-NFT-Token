// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import { Ownable2Step, Ownable } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20, IERC20, Address } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

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

    /* ========== STATE VARIABLES ========== */

    /// @dev One year time in seconds.
    uint256 private constant _ONE_YEAR_TIME = 31_536_000 seconds;

    /// @inheritdoc IBase
    address public immutable FEE_WALLET;

    /// @inheritdoc IBase
    uint256 public immutable VESTING_DEADLINE;

    /// @inheritdoc IBase
    uint256 public immutable BASE_COST_SINGLE;

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
     * @param feeWallet_ Address of the fee wallet.
     * @param baseCostSingle_ Base cost for a single NFT.
     * @param baseURI_ Base URI for computing the {tokenURI}.
     * @param tokens_ Addresses of the tokens to be registered as payment
     * tokens.
     * @param priceFeeds_ Addresses of the price feed oracles relevant to a
     * registered payment token.
     */
    constructor(
        address owner_,
        string memory name_,
        string memory symbol_,
        address feeWallet_,
        uint256 baseCostSingle_,
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
        VESTING_DEADLINE = block.timestamp + _ONE_YEAR_TIME;
        BASE_COST_SINGLE = baseCostSingle_;

        _setBaseURI(baseURI_);

        for (uint256 i = 0; i < length; ++i) {
            _updatePriceFeed(tokens_[i], priceFeeds_[i]);
        }
    }

    /* ========== FUNCTIONS ========== */

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
        if (block.timestamp < VESTING_DEADLINE) {
            address sender = msg.sender;
            uint32 size;

            assembly {
                size := extcodesize(sender)
            }

            if (size > 0) {
                _revert(SubceededVestingDeadline.selector);
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
     * @inheritdoc ERC721A
     * @dev Overridden to return a state variable.
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
     * @dev Implements set base uri logic.
     */
    function _setBaseURI(string memory newBaseURI) private {
        if (bytes(newBaseURI).length == 0) {
            _revert(InvalidString.selector);
        }

        if (newBaseURI.equal(baseURI)) {
            _revert(InvalidAssignment.selector);
        }

        emit SetBaseURI(newBaseURI, baseURI);

        baseURI = newBaseURI;
    }

    /**
     * @dev Implements update price feed logic.
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

        emit UpdatePriceFeed(token, newPriceFeed, priceFeed);
    }
}
