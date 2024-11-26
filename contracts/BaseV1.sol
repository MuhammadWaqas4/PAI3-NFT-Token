// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import { Ownable2Step, Ownable } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20, IERC20, Address } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { ERC721A, IERC721A } from "erc721a/contracts/ERC721A.sol";

import { ErrorsV2 } from "./interfaces/Errors.sol";
import { IBaseV1 } from "./interfaces/IBaseV1.sol";

/**
 * @title BaseV1.
 * @author PAI3 Team.
 * @notice BaseV1 NFT collection.
 */
abstract contract BaseV1 is Ownable2Step, ERC721A, ErrorsV2, IBaseV1 {
    using SafeERC20 for IERC20;
    using Address for address payable;
    using Strings for string;

    /* ========== STATE VARIABLES ========== */

    /// @inheritdoc IBaseV1
    IERC20 public constant ETH =
        IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// @inheritdoc IBaseV1
    address public immutable FEE_WALLET;

    /// @inheritdoc IBaseV1
    uint256 public immutable VESTING_DEADLINE;

    /// @inheritdoc IBaseV1
    uint256 public immutable BASE_COST_SINGLE;

    /// @dev Cap on the number of minted tokens.
    uint256 private immutable _CAP;

    /// @inheritdoc IBaseV1
    string public baseURI;

    /// @inheritdoc IBaseV1
    mapping(IERC20 token => AggregatorV3Interface priceFeed) public priceFeeds;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Constructor. Assigns ownership and initializes variables.
     * @param owner_ Address of the contract owner.
     * @param name_ Token collection name.
     * @param symbol_ Token collection symbol.
     * @param baseURI_ Base URI for computing the {tokenURI}.
     * @param feeWallet_ Address of the fee wallet.
     * @param baseCostSingle_ Base cost for a single NFT.
     * @param cap_ Cap on the number of minted tokens.
     * @param tokens_ Addresses of the tokens to be registered as payment
     * tokens.
     * @param priceFeeds_ Addresses of the price feed oracles relevant to a
     * registered payment token.
     */
    constructor(
        address owner_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address feeWallet_,
        uint256 baseCostSingle_,
        uint256 cap_,
        IERC20[] memory tokens_,
        AggregatorV3Interface[] memory priceFeeds_
    ) Ownable(owner_) ERC721A(name_, symbol_) {
        if (feeWallet_ == address(0)) {
            _revert(InvalidAddress.selector);
        }

        if (baseCostSingle_ == 0 || cap_ == 0) {
            _revert(InvalidValue.selector);
        }

        uint256 length = tokens_.length;

        if (length != priceFeeds_.length) {
            _revert(ArgumentArityMismatch.selector);
        }

        _setBaseURI(baseURI_);

        FEE_WALLET = feeWallet_;
        VESTING_DEADLINE = block.timestamp + 25 weeks;
        BASE_COST_SINGLE = baseCostSingle_;
        _CAP = cap_;

        for (uint256 i = 0; i < length; ++i) {
            _updatePriceFeed(tokens_[i], priceFeeds_[i]);
        }
    }

    /* ========== FUNCTIONS ========== */

    /**
     * @inheritdoc IBaseV1
     */
    function purchaseETH(uint256 quantity) external payable {
        if (msg.value == 0) {
            _revert(InvalidPayableValue.selector);
        }

        IERC20 token = ETH;
        uint8 tokenDecimals = 18;
        uint256 cost = _purchase(token, tokenDecimals, quantity);

        payable(FEE_WALLET).sendValue(cost);

        if (msg.value > cost) {
            payable(msg.sender).sendValue(msg.value - cost);
        }

        _safeMint(msg.sender, quantity);
    }

    /**
     * @inheritdoc IBaseV1
     */
    function purchase(IERC20 token, uint256 quantity) external {
        if (address(token) == address(0)) {
            _revert(InvalidPaymentToken.selector);
        }

        uint8 tokenDecimals = IERC20Metadata(address(token)).decimals();
        uint256 cost = _purchase(token, tokenDecimals, quantity);

        token.safeTransferFrom(msg.sender, FEE_WALLET, cost);

        _safeMint(msg.sender, quantity);
    }

    /**
     * @inheritdoc IBaseV1
     */
    function setBaseURI(
        string memory newBaseURI
    ) external onlyOwner returns (bool) {
        _setBaseURI(newBaseURI);

        return true;
    }

    /**
     * @inheritdoc IBaseV1
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
                _revert(VestingDeadlineNotReached.selector);
            }
        }

        super.transferFrom(from, to, tokenId);
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
    ) public view override(ERC721A, IERC721A) returns (bool) {
        return
            interfaceId == type(IBaseV1).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc ERC721A
     * @dev Overridden to include cap on token's total supply.
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
     * @dev Implements purchase logic.
     */
    function _purchase(
        IERC20 token,
        uint8 tokenDecimals,
        uint256 quantity
    ) private returns (uint256) {
        if (quantity == 0) {
            _revert(InvalidQuantity.selector);
        }

        uint256 baseCost = quantity * BASE_COST_SINGLE;

        AggregatorV3Interface priceFeed = priceFeeds[token];

        if (address(priceFeed) == address(0)) {
            _revert(PaymentTokenNotRegistered.selector);
        }

        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 normalization = priceFeed.decimals() + tokenDecimals;
        uint256 cost = (baseCost * 10 ** normalization) / uint256(price);

        if (cost == 0) {
            _revert(InvalidCost.selector);
        }

        emit Purchased({
            purchaser: msg.sender,
            token: token,
            fromTokenId: _nextTokenId(),
            quantity: quantity,
            cost: cost
        });

        return cost;
    }

    /**
     * @dev Implements set base uri logic.
     */
    function _setBaseURI(string memory newBaseURI) private {
        if (bytes(newBaseURI).length == 0) {
            _revert(InvalidString.selector);
        }

        if (newBaseURI.equal(baseURI)) {
            _revert(IdenticalStringAssignment.selector);
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

        emit PriceFeedUpdated(token, newPriceFeed, priceFeed);
    }
}
