// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "forge-std/Test.sol";

import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/**
 * @title SignHelper.
 * @author PAI3 Team.
 * @notice ECDSA sign helper.
 */
contract SignHelper is Test {
    using MessageHashUtils for bytes32;

    /* ========== HELPER FUNCTIONS ========== */

    function _sign(
        address caller,
        uint256 startTokenId,
        uint256 deadline,
        uint256 signerPrivateKey
    ) internal pure returns (bytes memory) {
        bytes32 messageHash = keccak256(
            abi.encodePacked(caller, startTokenId, deadline)
        );

        bytes32 digest = messageHash.toEthSignedMessageHash();

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);

        bytes memory signature = abi.encodePacked(r, s, v);

        return signature;
    }
}
