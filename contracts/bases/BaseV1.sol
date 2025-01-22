// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { ERC721A, IERC721A } from "erc721a/contracts/ERC721A.sol";

import { BaseV1Errors } from "../interfaces/Errors.sol";
import { IBaseV1 } from "../interfaces/IBaseV1.sol";

import { Base } from "./Base.sol";

/**
 * @title BaseV1.
 * @author PAI3 Team.
 * @notice First extended variant of the base NFT collection.
 */
abstract contract BaseV1 is BaseV1Errors, IBaseV1, Base {
    using SafeERC20 for IERC20;
    using Address for address payable;

    /* ========================== STATE VARIABLES ========================== */

    /// @dev One year time in seconds.
    uint256 private constant _ONE_YEAR_TIME = 31_536_000 seconds;

    /// @dev Cap on the number of minted tokens.
    uint256 private immutable _CAP;

    /* ========================== CONSTRUCTOR ========================== */

    /**
     * @dev Constructor. Initializes parent contract.
     * @param params_ Params necessary for contract deployment.
     * @param cap_ Cap on the number of minted tokens.
     */
    constructor(BaseParams memory params_, uint256 cap_) Base(params_) {
        if (cap_ == 0) {
            _revert(InvalidValue.selector);
        }

        _CAP = cap_;
    }

    /* ========================== FUNCTIONS ========================== */

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
}
