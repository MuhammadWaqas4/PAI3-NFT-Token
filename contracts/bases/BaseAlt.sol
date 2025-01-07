// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { Ownable2Step, Ownable } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { ERC721, IERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { BaseAltErrors } from "../interfaces/Errors.sol";
import { IBaseAlt } from "../interfaces/IBaseAlt.sol";

import { _revert } from "../utils/Globals.sol";

/**
 * @title BaseAlt.
 * @author PAI3 Team.
 * @notice Alternative base NFT collection.
 */
abstract contract BaseAlt is Ownable2Step, ERC721, BaseAltErrors, IBaseAlt {
    using Strings for string;

    /* ========== STATE VARIABLES ========== */

    /// @inheritdoc IBaseAlt
    uint256 public totalSupply;

    /// @inheritdoc IBaseAlt
    string public baseURI;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Constructor. Assigns ownership and initializes variables.
     * @param paramsAlt_ Params necessary for contract deployment.
     */
    constructor(
        BaseAltParams memory paramsAlt_
    ) Ownable(paramsAlt_.owner) ERC721(paramsAlt_.name, paramsAlt_.symbol) {
        _setBaseURI(paramsAlt_.baseURI);
    }

    /* ========== FUNCTIONS ========== */

    /**
     * @inheritdoc IBaseAlt
     */
    function mint() external {
        if (balanceOf(msg.sender) > 0) {
            _revert(AlreadyOwned.selector);
        }

        totalSupply++;

        emit Mint({ minter: msg.sender, tokenId: totalSupply });

        _mint(msg.sender, totalSupply);
    }

    /**
     * @inheritdoc IBaseAlt
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _setBaseURI(newBaseURI);
    }

    /**
     * @inheritdoc ERC721
     * @dev Overridden to include this contracts `interfaceId`.
     * @param interfaceId Id of the required interface.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, IERC165) returns (bool) {
        return
            interfaceId == type(IBaseAlt).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc ERC721
     * @dev Overridden to return {baseURI}.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
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
}
