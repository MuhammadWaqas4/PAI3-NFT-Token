// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "forge-std/Test.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IDynamis } from "contracts/interfaces/IDynamis.sol";

abstract contract TestStorage is Test {
    /* ========================== STATE VARIABLES ========================== */

    address public secondary;
    address public tertiary;

    uint256 public signerPrivateKey;
    uint256 public secondarySignerPrivateKey;

    uint256 public totalSupply;
    uint256 public initialCap;

    string[] public names;
    string[] public symbols;
    uint256[] public rewardPerSeconds;
    uint256[] public baseCostSingles;
    uint256[] public caps;

    uint64[] public rewardDurations;

    address public owner;
    address public treasuryWallet;
    address public rewardWallet;
    address public signer;
    address public secondarySigner;
    string public baseURI;

    /* ========================== TYPES ========================== */

    struct MintParams {
        uint256 deadline;
        uint256 privateKey;
        uint256 quantity;
        uint256 cost;
        address caller;
        IERC20 token;
        IDynamis collection;
        bytes4 errorSelector;
    }

    /* ========================== CONSTRUCTOR ========================== */

    constructor() {
        secondary = address(0xAAA);
        tertiary = address(0xBBB);

        signerPrivateKey = 100;
        secondarySignerPrivateKey = 200;

        totalSupply = vm.envUint("TOTAL_SUPPLY");
        initialCap = vm.envUint("INITIAL_CAP");

        names = vm.envString("NAMES", "|");
        symbols = vm.envString("SYMBOLS", "|");
        rewardPerSeconds = vm.envUint("REWARD_PER_SECONDS", "|");
        baseCostSingles = vm.envUint("BASE_COST_SINGLES", "|");
        caps = vm.envUint("CAPS", "|");

        uint256[] memory tempRewardDurations = vm.envUint(
            "REWARD_DURATIONS",
            "|"
        );

        for (uint256 i = 0; i < tempRewardDurations.length; i++) {
            rewardDurations.push(uint64(tempRewardDurations[i]));
        }

        owner = address(0xCCC);
        treasuryWallet = address(0xDDD);
        rewardWallet = address(0xEEE);
        signer = vm.addr(signerPrivateKey);
        secondarySigner = vm.addr(secondarySignerPrivateKey);
        baseURI = "ipfs://";

        vm.label(secondary, "secondary");
        vm.label(tertiary, "tertiary");
        vm.label(owner, "owner");
        vm.label(treasuryWallet, "treasuryWallet");
        vm.label(rewardWallet, "rewardWallet");
        vm.label(signer, "signer");
        vm.label(secondarySigner, "secondarySigner");
    }
}
