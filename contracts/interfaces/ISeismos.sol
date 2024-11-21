// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { IPAI3 } from "./IPAI3.sol";

/**
 * @title ISeismos.
 * @author PAI3 Team.
 * @notice Seismos NFT collection interface.
 */
interface ISeismos is IERC721 {
    /* ========== EVENTS ========== */

    /**
     * @dev Emitted when a token is purchased by `purchaser`.
     */
    event Purchased(address indexed purchaser, uint256 tokenId);

    /**
     * @dev Emitted when {baseURI} is changed to `newBaseURI` from `oldBaseURI`.
     */
    event SetBaseURI(string newBaseURI, string oldBaseURI);

    /* ========== FUNCTIONS ========== */

    /**
     * @notice Mints a token and transfers it to the caller.
     */
    function purchase() external;

    /**
     * @notice Sets the value for {baseURI}.
     * NOTE: Only `owner` can call this function.
     * @param newBaseURI Value to set the {baseURI} to.
     */
    function setBaseURI(string memory newBaseURI) external returns (bool);

    /**
     * @notice Base URI for computing {tokenURI}. If set, the resulting URI for
     * each token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    function baseURI() external view returns (string memory);
}
