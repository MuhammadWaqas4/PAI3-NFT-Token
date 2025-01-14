// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title IBaseAlt.
 * @author PAI3 Team.
 * @notice BaseAlt NFT collection interface.
 */
interface IBaseAlt is IERC721 {
    /* ========================== TYPES ========================== */

    struct BaseAltParams {
        /// @custom:member owner Address of the contract owner.
        address owner;
        /// @custom:member name Token collection name.
        string name;
        /// @custom:member symbol Token collection symbol.
        string symbol;
        /// @custom:member baseURI Base URI for computing the tokenURI.
        string baseURI;
    }

    /* ========================== EVENTS ========================== */

    /**
     * @dev Emitted when `token` is minted by `minter`.
     */
    event Mint(address indexed minter, uint256 tokenId);

    /**
     * @dev Emitted when `base URI` is changed to `newBaseURI` from
     * `oldBaseURI`.
     */
    event SetBaseURI(string newBaseURI, string oldBaseURI);

    /* ========================== FUNCTIONS ========================== */

    /**
     * @notice Mints `token` and transfers it to the `caller`.
     */
    function mint() external;

    /**
     * @notice Sets the value for `baseURI`.
     * NOTE: Only `owner` can call this function.
     * @param newBaseURI Value to set the baseURI to.
     */
    function setBaseURI(string memory newBaseURI) external;

    /**
     * @dev Total number of `tokens` in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice `Base URI` for computing {tokenURI}. If set, the resulting URI
     * for each `token` will be the concatenation of the `base URI` and the
     * `tokenId`.
     */
    function baseURI() external view returns (string memory);
}
