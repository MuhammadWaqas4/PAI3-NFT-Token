// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "forge-std/Test.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IDynamis } from "contracts/interfaces/IDynamis.sol";

abstract contract TestStorage is Test {
    /* ========================== STATE VARIABLES ========================== */

    address public secondary;
    address public tertiary;

    uint256 public secondarySignerPrivateKey;
    address public secondarySigner;

    uint256 public totalSupply;

    address public owner;

    string public name;
    string public symbol;

    uint256 public initialCap;
    uint256 public cap;
    uint64 public rewardDuration;
    uint256 public rewardPerSecond;
    uint256 public baseCostSingle;

    address public treasuryWallet;
    address public rewardWallet;
    uint256 public signerPrivateKey;
    address public signer;
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

        secondarySignerPrivateKey = 200;
        secondarySigner = vm.addr(secondarySignerPrivateKey);

        totalSupply = vm.envUint("TOTAL_SUPPLY");

        owner = address(0xCCC);

        name = vm.envString("NAME");
        symbol = vm.envString("SYMBOL");

        initialCap = vm.envUint("INITIAL_CAP");
        cap = vm.envUint("CAP");
        rewardDuration = uint64(vm.envUint("REWARD_DURATION"));
        rewardPerSecond = vm.envUint("REWARD_PER_SECOND");
        baseCostSingle = vm.envUint("BASE_COST_SINGLE");

        treasuryWallet = address(0xDDD);
        rewardWallet = address(0xEEE);
        signerPrivateKey = 100;
        signer = vm.addr(signerPrivateKey);
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
