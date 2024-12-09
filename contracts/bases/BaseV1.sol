// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20, IERC20, Address } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { ERC721A, IERC721A } from "erc721a/contracts/ERC721A.sol";

import { BaseV1Errors } from "../interfaces/Errors.sol";
import { IBaseV1 } from "../interfaces/IBaseV1.sol";

import { Base } from "./Base.sol";

import { _ETH } from "../Globals.sol";

/**
 * @title BaseV1.
 * @author PAI3 Team.
 * @notice Base NFT collection version 1.
 */
abstract contract BaseV1 is BaseV1Errors, IBaseV1, Base {
    using SafeERC20 for IERC20;
    using Address for address payable;

    /* ========== STATE VARIABLES ========== */

    /// @dev One year time in seconds.
    uint256 private constant _ONE_YEAR_TIME = 31_536_000 seconds;

    /// @dev Cap on the number of minted tokens.
    uint256 private immutable _CAP;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Constructor. Assigns ownership and initializes variables.
     * @param owner_ Address of the contract owner.
     * @param name_ Token collection name.
     * @param symbol_ Token collection symbol.
     * @param feeWallet_ Address of the fee wallet.
     * @param baseCostSingle_ Base cost for a single NFT.
     * @param baseURI_ Base URI for computing the tokenURI.
     * @param tokens_ Addresses of the tokens to be registered as payment
     * tokens.
     * @param priceFeeds_ Addresses of the price feed relevant to a registered
     * payment token.
     * @param cap_ Cap on the number of minted tokens.
     */
    constructor(
        address owner_,
        string memory name_,
        string memory symbol_,
        address feeWallet_,
        uint256 baseCostSingle_,
        string memory baseURI_,
        IERC20[] memory tokens_,
        AggregatorV3Interface[] memory priceFeeds_,
        uint256 cap_
    )
        Base(
            owner_,
            name_,
            symbol_,
            feeWallet_,
            baseCostSingle_,
            baseURI_,
            tokens_,
            priceFeeds_
        )
    {
        if (cap_ == 0) {
            _revert(InvalidValue.selector);
        }

        _CAP = cap_;
    }

    /* ========== FUNCTIONS ========== */

    /**
     * @inheritdoc IBaseV1
     */
    function mintWithETH(uint256 quantity) external payable {
        if (msg.value == 0) {
            _revert(InvalidPayableValue.selector);
        }

        IERC20 token = _ETH;
        uint8 tokenDecimals = 18;
        uint256 cost = _processMint(token, tokenDecimals, quantity);

        payable(FEE_WALLET).sendValue(cost);

        if (msg.value > cost) {
            payable(msg.sender).sendValue(msg.value - cost);
        }

        _safeMint(msg.sender, quantity);
    }

    /**
     * @inheritdoc IBaseV1
     */
    function mint(IERC20 token, uint256 quantity) external {
        if (address(token) == address(0)) {
            _revert(InvalidAddress.selector);
        }

        uint8 tokenDecimals = IERC20Metadata(address(token)).decimals();
        uint256 cost = _processMint(token, tokenDecimals, quantity);

        token.safeTransferFrom(msg.sender, FEE_WALLET, cost);

        _safeMint(msg.sender, quantity);
    }

    /**
     * @inheritdoc IBaseV1
     */
    function cap() public view returns (uint256) {
        return _CAP;
    }

    /**
     * @inheritdoc ERC721A
     * @dev Overridden to include this contracts `interfaceId`.
     * @param interfaceId Id of the required interface.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(Base, IERC721A) returns (bool) {
        return
            interfaceId == type(IBaseV1).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc ERC721A
     * @dev Overridden to introduce {cap} to `token`'s {totalSupply}.
     */
    function _mint(address to, uint256 quantity) internal override {
        super._mint(to, quantity);

        uint256 maxSupply = cap();
        uint256 supply = totalSupply();

        if (supply > maxSupply) {
            _revert(ExceededCap.selector);
        }
    }

    /**
     * @dev Implements {mint} logic.
     */
    function _processMint(
        IERC20 token,
        uint8 tokenDecimals,
        uint256 quantity
    ) private returns (uint256) {
        if (quantity == 0) {
            _revert(InvalidValue.selector);
        }

        uint256 baseCost = quantity * BASE_COST_SINGLE;

        AggregatorV3Interface priceFeed = priceFeeds[token];

        if (address(priceFeed) == address(0)) {
            _revert(IncorrectPaymentToken.selector);
        }

        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 normalization = priceFeed.decimals() + tokenDecimals;
        uint256 cost = (baseCost * 10 ** normalization) / uint256(price);

        if (cost == 0) {
            _revert(InsufficientCost.selector);
        }

        emit Mint({
            minter: msg.sender,
            token: token,
            fromTokenId: _nextTokenId(),
            quantity: quantity,
            cost: cost
        });

        return cost;
    }
}
