// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import { Ownable2Step, Ownable } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { SafeERC20, IERC20, Address } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { ERC721A, IERC721A } from "erc721a/contracts/ERC721A.sol";

import { Errors } from "./interfaces/Errors.sol";
import { IBase } from "./interfaces/IBase.sol";

/**
 * @title Base.
 * @author Muhammad Waqas.
 * @notice Base NFT collection.
 */
contract Base is Ownable2Step, ERC721A, Errors, IBase {
    using SafeERC20 for IERC20;
    using Address for address payable;
    using Strings for string;

    /* ========== STATE VARIABLES ========== */

    /// @inheritdoc IBase
    uint256 public immutable BASE_MINT_FEE;

    /// @inheritdoc IBase
    uint256 public immutable CAP;

    /// @inheritdoc IBase
    address public immutable FUNDS_WALLET;

    /// @inheritdoc IBase
    IERC20 public immutable USDT;

    /// @inheritdoc IBase
    string public baseURI;

    /// @inheritdoc IBase
    mapping(IERC20 token => AggregatorV3Interface priceFeed) public priceFeeds;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Constructor. Assigns ownership, initializes immutable variables and
     * sets base URI.
     * @param owner_ Address of the contract owner.
     * @param name_ Token collection name.
     * @param symbol_ Token collection symbol.
     * @param baseMintFee_ Base minting fee in USD.
     * @param cap_ Cap on the token's total supply.
     * @param fundsWallet_ Address of the funds collection wallet.
     * @param usdt_ Address of the Tether USD token.
     * @param baseURI_ Base URI for computing the {tokenURI}.
     * @param tokens_ Addresses of the mint fee tokens.
     * @param priceFeeds_ Addresses of the price feed oracles.
     */
    constructor(
        address owner_,
        string memory name_,
        string memory symbol_,
        uint256 baseMintFee_,
        uint256 cap_,
        address fundsWallet_,
        IERC20 usdt_,
        string memory baseURI_,
        IERC20[] memory tokens_,
        AggregatorV3Interface[] memory priceFeeds_
    ) Ownable(owner_) ERC721A(name_, symbol_) {
        _setBaseURI(baseURI_);
        BASE_MINT_FEE = baseMintFee_;
        CAP = cap_;
        FUNDS_WALLET = fundsWallet_;
        USDT = usdt_;

        for (uint256 i = 0; i < priceFeeds_.length; ++i) {
            priceFeeds[tokens_[i]] = priceFeeds_[i];
        }
    }

    /* ========== FUNCTIONS ========== */

    /**
     * @inheritdoc IBase
     */
    function safeMint(
        IERC20 token,
        address to,
        uint256 quantity
    ) external payable returns (bool) {
        uint256 mintFee = quantity * BASE_MINT_FEE;

        if (msg.value == 0) {
            USDT.safeTransferFrom(msg.sender, FUNDS_WALLET, mintFee);
        } else {
            (, int256 price, , , ) = priceFeeds[token].latestRoundData();
            uint256 mintFeeETH = (mintFee * 1e20) / uint256(price);
            payable(FUNDS_WALLET).sendValue(mintFeeETH);

            if (msg.value > mintFeeETH) {
                payable(msg.sender).sendValue(msg.value - mintFeeETH);
            }
        }

        _safeMint(to, quantity);

        return true;
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
     * @inheritdoc ERC721A
     * @dev Overridden to add vesting check.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @inheritdoc ERC721A
     * @dev Overridden to add vesting check.
     */
    function approve(
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) {
        super.approve(to, tokenId);
    }

    /**
     * @inheritdoc ERC721A
     * @dev Overridden to add vesting check.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721A, IERC721A) {
        super.setApprovalForAll(operator, approved);
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
     * @dev Internal set base uri logic.
     */
    function _setBaseURI(string memory newBaseURI) internal {
        if (newBaseURI.equal(baseURI)) {
            revert IdenticalStringAssignment(newBaseURI, baseURI);
        }

        emit SetBaseURI(newBaseURI, baseURI);

        baseURI = newBaseURI;
    }

    /**
     * @inheritdoc ERC721A
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @inheritdoc ERC721A
     * @dev Overridden to change {_sequentialUpTo} to `1000` so that total
     * supply may also be limited.
     */
    function _sequentialUpTo() internal pure override returns (uint256) {
        return 1000;
    }

    /**
     * @inheritdoc ERC721A
     * @dev Overridden to change {_startTokenId} to `1`.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}
