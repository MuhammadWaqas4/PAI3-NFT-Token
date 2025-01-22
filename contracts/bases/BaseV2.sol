// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

import { ERC721A, IERC721A } from "erc721a/contracts/ERC721A.sol";

import { BaseV2Errors } from "../interfaces/Errors.sol";
import { IBaseV2 } from "../interfaces/IBaseV2.sol";

import { Base } from "./Base.sol";

/**
 * @title BaseV2.
 * @author PAI3 Team.
 * @notice Second extended variant of the base NFT collection.
 */
abstract contract BaseV2 is Pausable, BaseV2Errors, IBaseV2, Base {
    using SafeERC20 for IERC20;
    using Address for address payable;

    /* ========================== STATE VARIABLES ========================== */

    /// @dev One year time in seconds.
    uint256 private constant _ONE_YEAR_TIME = 31_536_000 seconds;

    /// @dev Cap on the number of minted `tokens` initially.
    /// NOTE: Once this cap is reached further minting will be paused until the
    /// next phase.
    uint256 private immutable _INITIAL_CAP;

    /// @dev Cap on the number of minted `tokens`.
    /// NOTE: This value is inclusive of {_INITIAL_CAP}.
    uint256 private immutable _CAP;

    /// @inheritdoc IBaseV2
    Phase public phase;

    /* ========================== CONSTRUCTOR ========================== */

    /**
     * @dev Constructor. Initializes parent contract.
     * @param params_ Params necessary for contract deployment.
     * @param initialCap_ Cap on the number of minted tokens initially.
     * @param cap_ Cap on the number of minted tokens.
     */
    constructor(
        BaseParams memory params_,
        uint256 initialCap_,
        uint256 cap_
    ) Base(params_) {
        if (initialCap_ == 0 || cap_ == 0) {
            _revert(InvalidValue.selector);
        }

        if (initialCap_ >= cap_) {
            _revert(InvalidInitialCap.selector);
        }

        if (cap_ > type(uint24).max) {
            _revert(InvalidCap.selector);
        }

        _INITIAL_CAP = initialCap_;
        _CAP = cap_;
    }

    /* ========================== FUNCTIONS ========================== */

    /**
     * @inheritdoc IBaseV2
     */
    function bumpPhase() external onlyOwner {
        if (phase != Phase.FIRST) {
            _revert(AlreadyBumpedPhase.selector);
        }

        _unpause();
        phase = Phase.SECOND;
    }

    /**
     * @inheritdoc IBaseV2
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @inheritdoc IBaseV2
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @inheritdoc IBaseV2
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
    ) public view override(Base, IERC721A) returns (bool) {
        return
            interfaceId == type(IBaseV2).interfaceId ||
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

        if (supply == maxSupply && phase == Phase.FIRST) {
            _pause();
        }
    }

    /**
     * @inheritdoc Base
     * @dev Overridden to add pausing checks.
     * NOTE: Can only be called when `unpaused`.
     */
    function _processMint(
        IERC20 token,
        uint8 tokenDecimals,
        uint256 quantity,
        uint256 deadline,
        bytes memory signature
    ) internal override whenNotPaused returns (uint256) {
        return
            super._processMint(
                token,
                tokenDecimals,
                quantity,
                deadline,
                signature
            );
    }
}
