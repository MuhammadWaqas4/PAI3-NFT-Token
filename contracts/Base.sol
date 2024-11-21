// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import { Ownable2Step, Ownable } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20, IERC20, Address } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { ERC721A, IERC721A } from "erc721a/contracts/ERC721A.sol";

import { Errors } from "./interfaces/Errors.sol";
import { IBase } from "./interfaces/IBase.sol";

/**
 * @title Base.
 * @author Muhammad Waqas.
 * @notice Base NFT collection.
 */
contract Base is Ownable2Step, Pausable, ERC721A, Errors, IBase {
    using SafeERC20 for IERC20;
    using Address for address payable;
    using Strings for string;

    /* ========== STATE VARIABLES ========== */

    /// @inheritdoc IBase
    IERC20 public constant ETH =
        IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// @inheritdoc IBase
    address public immutable FEE_WALLET;

    /// @inheritdoc IBase
    uint256 public immutable VESTING_DEADLINE;

    /// @inheritdoc IBase
    uint256 public immutable BASE_COST_SINGLE;

    /// @dev Cap on the number of initially minted tokens.
    /// NOTE: Once this cap is reached further minting will be paused until the
    /// next phase.
    uint256 private immutable _INITIAL_CAP;

    /// @dev Cap on the number of minted tokens.
    /// NOTE: This value is inclusive of `_INITIAL_CAP`.
    uint256 private immutable _CAP;

    /// @inheritdoc IBase
    Phase public phase;

    /// @inheritdoc IBase
    string public baseURI;

    /// @inheritdoc IBase
    mapping(IERC20 token => AggregatorV3Interface priceFeed) public priceFeeds;

    /* ========== EVENTS ========== */

    event Sale(
        address indexed buyer,
        IERC20 token,
        uint256 baseCost,
        uint256 cost,
        uint256 fromTokenId,
        uint256 quantity
    );

    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Constructor. Assigns ownership, initializes immutable variables and
     * sets base URI.
     * @param owner_ Address of the contract owner.
     * @param name_ Token collection name.
     * @param symbol_ Token collection symbol.
     * @param baseURI_ Base URI for computing the {tokenURI}.
     * @param baseCostSingle_ Base cost for a single NFT.
     * @param initialCap_ Cap on the number of initially minted tokens.
     * @param cap_ Cap on the number of minted tokens.
     * @param feeWallet_ Address of the fee wallet.
     * @param tokens_ Addresses of the tokens to be used as payment methods.
     * @param priceFeeds_ Addresses of the price feed oracles.
     */
    constructor(
        address owner_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address feeWallet_,
        uint256 baseCostSingle_,
        uint256 initialCap_,
        uint256 cap_,
        IERC20[] memory tokens_,
        AggregatorV3Interface[] memory priceFeeds_
    ) Ownable(owner_) ERC721A(name_, symbol_) {
        if (feeWallet_ == address(0)) {
            revert InvalidAddress();
        }

        if (baseCostSingle_ == 0 || cap_ == 0) {
            revert InvalidValue();
        }

        uint256 length = tokens_.length;

        if (length != priceFeeds_.length) {
            revert ArgumentArityMismatch();
        }

        _setBaseURI(baseURI_);

        FEE_WALLET = feeWallet_;
        VESTING_DEADLINE = block.timestamp + 25 weeks;
        BASE_COST_SINGLE = baseCostSingle_;
        _INITIAL_CAP = initialCap_;
        _CAP = cap_;

        if (initialCap_ == 0) {
            phase = Phase.SECOND;
        }

        for (uint256 i = 0; i < length; ++i) {
            priceFeeds[tokens_[i]] = priceFeeds_[i];
        }
    }

    /* ========== FUNCTIONS ========== */

    /**
     * @inheritdoc IBase
     */
    function purchaseETH(uint256 quantity) external payable whenNotPaused {
        if (msg.value == 0) {
            revert InvalidPayableValue();
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
     * @inheritdoc IBase
     */
    function purchase(IERC20 token, uint256 quantity) external whenNotPaused {
        if (address(token) == address(0)) {
            revert InvalidToken();
        }

        uint8 tokenDecimals = IERC20Metadata(address(token)).decimals();
        uint256 cost = _purchase(token, tokenDecimals, quantity);

        token.safeTransferFrom(msg.sender, FEE_WALLET, cost);

        _safeMint(msg.sender, quantity);
    }

    /**
     * @inheritdoc IBase
     */
    function setBaseURI(
        string memory newBaseURI
    ) external onlyOwner returns (bool) {
        _setBaseURI(newBaseURI);

        return true;
    }

    /**
     * @inheritdoc IBase
     */
    function bumpPhase() external onlyOwner {
        _unpause();
        phase = Phase.SECOND;
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
                revert VestingDeadlineNotReached();
            }
        }

        super.transferFrom(from, to, tokenId);
    }

    /**
     * @inheritdoc IBase
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
            interfaceId == type(IBase).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Internal purchase logic.
     */
    function _purchase(
        IERC20 token,
        uint8 tokenDecimals,
        uint256 quantity
    ) internal returns (uint256) {
        if (quantity == 0) {
            revert InvalidQuantity();
        }

        uint256 baseCost = quantity * BASE_COST_SINGLE;

        AggregatorV3Interface priceFeed = priceFeeds[token];

        if (address(priceFeed) == address(0)) {
            revert InvalidPriceFeed();
        }

        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 normalization = priceFeed.decimals() + tokenDecimals;
        uint256 cost = (baseCost * 10 ** normalization) / uint256(price);

        if (cost == 0) {
            revert InvalidCost();
        }

        emit Sale({
            buyer: msg.sender,
            token: token,
            baseCost: baseCost,
            cost: cost,
            fromTokenId: _nextTokenId(),
            quantity: quantity
        });

        return cost;
    }

    /**
     * @dev Internal set base uri logic.
     */
    function _setBaseURI(string memory newBaseURI) internal {
        if (bytes(newBaseURI).length == 0) {
            revert InvalidString();
        }

        if (newBaseURI.equal(baseURI)) {
            revert IdenticalStringAssignment(newBaseURI, baseURI);
        }

        emit SetBaseURI(newBaseURI, baseURI);

        baseURI = newBaseURI;
    }

    /**
     * @inheritdoc ERC721A
     * @dev Overridden to include cap on token's total supply.
     */
    function _safeMint(address to, uint256 quantity) internal override {
        super._safeMint(to, quantity);

        uint256 maxSupply = cap();
        uint256 supply = totalSupply();

        if (supply > maxSupply) {
            revert ExceededCap(supply, maxSupply);
        }

        if (supply == maxSupply && phase == Phase.FIRST) {
            _pause();
        }
    }

    /**
     * @inheritdoc ERC721A
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
}
