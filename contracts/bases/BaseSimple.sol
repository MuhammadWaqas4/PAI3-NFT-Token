// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { Ownable2Step, Ownable } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { ERC721, IERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { BaseSimpleErrors } from "../interfaces/Errors.sol";
import { IBaseSimple } from "../interfaces/IBaseSimple.sol";

import { _revert } from "../utils/Globals.sol";

/**
 * @title BaseSimple.
 * @author PAI3 Team.
 * @notice Base NFT collection.
 */
abstract contract BaseSimple is
    Ownable2Step,
    ERC721,
    BaseSimpleErrors,
    IBaseSimple
{
    using Strings for string;

    /* ========== STATE VARIABLES ========== */

    /// @inheritdoc IBaseSimple
    uint256 public totalSupply;

    /// @inheritdoc IBaseSimple
    string public baseURI;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Constructor. Assigns ownership and initializes variables.
     * @param owner_ Address of the contract owner.
     * @param name_ Token collection name.
     * @param symbol_ Token collection symbol.
     * @param baseURI_ Base URI for computing the tokenURI.
     */
    constructor(
        address owner_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) Ownable(owner_) ERC721(name_, symbol_) {
        _setBaseURI(baseURI_);
    }

    /* ========== FUNCTIONS ========== */

    /**
     * @inheritdoc IBaseSimple
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
     * @inheritdoc IBaseSimple
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
            interfaceId == type(IBaseSimple).interfaceId ||
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
