// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { Ownable2Step, Ownable } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { SeismosErrors } from "../interfaces/Errors.sol";
import { ISeismos } from "../interfaces/ISeismos.sol";

/**
 * @title Seismos.
 * @author PAI3 Team.
 * @notice Seismos NFT collection.
 */
contract Seismos is Ownable2Step, ERC721, SeismosErrors, ISeismos {
    using Strings for string;

    /* ========== STATE VARIABLES ========== */

    /// @inheritdoc ISeismos
    uint256 public totalSupply;

    /// @inheritdoc ISeismos
    string public baseURI;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Constructor. Assigns ownership and initializes variables.
     * @param owner_ Address of the contract owner.
     * @param baseURI_ Base URI for computing the {tokenURI}.
     */
    constructor(
        address owner_,
        string memory baseURI_
    ) Ownable(owner_) ERC721("Seismos", "SES") {
        totalSupply = 1;

        _setBaseURI(baseURI_);
    }

    /* ========== FUNCTIONS ========== */

    /**
     * @inheritdoc ISeismos
     */
    function purchase() external {
        if (balanceOf(msg.sender) > 0) {
            _revert(AlreadyPurchased.selector);
        }

        emit Purchased({ purchaser: msg.sender, tokenId: totalSupply });

        _mint(msg.sender, totalSupply);

        totalSupply++;
    }

    /**
     * @inheritdoc ISeismos
     */
    function setBaseURI(
        string memory newBaseURI
    ) external onlyOwner returns (bool) {
        _setBaseURI(newBaseURI);

        return true;
    }

    /**
     * @inheritdoc ERC721
     * @dev Overridden to return a state variable.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
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
     * @dev For more efficient reverts.
     */
    function _revert(bytes4 errorSelector) private pure {
        assembly {
            mstore(0x00, errorSelector)
            revert(0x00, 0x04)
        }
    }
}
