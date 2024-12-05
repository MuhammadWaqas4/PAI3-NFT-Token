// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { IPAI3 } from "./IPAI3.sol";

/**
 * @title IBaseSimple.
 * @author PAI3 Team.
 * @notice BaseSimple NFT collection interface.
 */
interface IBaseSimple is IERC721 {
    /* ========== EVENTS ========== */

    /**
     * @dev Emitted when a token is minted by `minter`.
     */
    event Mint(address indexed minter, uint256 tokenId);

    /**
     * @dev Emitted when {baseURI} is changed to `newBaseURI` from `oldBaseURI`.
     */
    event SetBaseURI(string newBaseURI, string oldBaseURI);

    /* ========== FUNCTIONS ========== */

    /**
     * @notice Mints a token and transfers it to the caller.
     */
    function mint() external;

    /**
     * @notice Sets the value for {baseURI}.
     * NOTE: Only `owner` can call this function.
     * @param newBaseURI Value to set the {baseURI} to.
     */
    function setBaseURI(string memory newBaseURI) external;

    /**
     * @dev Total number of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Base URI for computing {tokenURI}. If set, the resulting URI for
     * each token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    function baseURI() external view returns (string memory);
}
