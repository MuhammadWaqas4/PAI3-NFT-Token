// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "forge-std/Test.sol";

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import { Dynamis } from "contracts/collections/Dynamis.sol";

import { BaseErrors, BaseV2Errors } from "contracts/interfaces/Errors.sol";
import { IBase } from "contracts/interfaces/IBase.sol";

import { PAI3 } from "contracts/token/PAI3.sol";

import { _ETH } from "contracts/utils/Globals.sol";

import { MockPriceFeed } from "./externals/MockPriceFeed.sol";
import { MockToken } from "./externals/MockToken.sol";

import { SignHelper } from "./helpers/SignHelper.sol";

import { secondary, totalSupply, owner, feeWallet, rewardWallet, signerPrivateKey, initialCap, invalidSignerPrivateKey } from "./utils/TestGlobals.sol";

/**
 * @title DynamisTest.
 * @author PAI3 Team.
 * @notice Test cases for dynamis.
 */
contract DynamisTest is ERC721Holder, SignHelper {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 public pai3;

    IERC20 public usdt;

    AggregatorV3Interface public priceFeedETH;
    AggregatorV3Interface public priceFeedUSDT;

    address public signer;

    string public name = "Dynamis";
    string public symbol = "DYS";
    uint64 public rewardDuration = 31449600;
    uint256 public rewardPerSecond = 921665140415140;
    uint256 public baseCostSingle = 1000;
    string public baseURI = "ipfs://abc/";
    IERC20[] public tokens;
    AggregatorV3Interface[] public priceFeeds;
    uint256 public cap = 10000;

    Dynamis public dynamis;

    address public invalidSigner;

    /* ========== SETUP ========== */

    function setUp() external {
        pai3 = IERC20(new PAI3(owner, rewardWallet, totalSupply));

        vm.deal(address(this), 1_000_000_000 * 1e18);
        usdt = IERC20(
            new MockToken("Tether USD", "USDT", 6, 1_000_000_000 * 1e6)
        );
        tokens = [_ETH, usdt];

        priceFeedETH = AggregatorV3Interface(
            address(new MockPriceFeed(8, 4000 * 1e8))
        );
        priceFeedUSDT = AggregatorV3Interface(
            address(new MockPriceFeed(8, 1 * 1e8))
        );
        priceFeeds = [priceFeedETH, priceFeedUSDT];

        signer = vm.addr(signerPrivateKey);

        dynamis = new Dynamis(
            IBase.BaseParams({
                owner: owner,
                name: name,
                symbol: symbol,
                rewardDuration: rewardDuration,
                rewardPerSecond: rewardPerSecond,
                baseCostSingle: baseCostSingle,
                pai3: pai3,
                feeWallet: feeWallet,
                rewardWallet: rewardWallet,
                signer: signer,
                baseURI: baseURI,
                tokens: tokens,
                priceFeeds: priceFeeds
            }),
            initialCap,
            cap
        );

        invalidSigner = vm.addr(invalidSignerPrivateKey);
    }

    /* ========== RECEIVE ========== */

    receive() external payable {}

    /* ========== TEST FUNCTIONS ========== */

    function test_MintWithETH() external {
        uint256 costPerToken = 0.25 * 1e18;
        uint256 deadline = block.timestamp + 1;

        // Testing with single quantity.

        address caller = address(this);
        uint256 startTokenId = dynamis.totalSupply() + 1;
        bytes memory signature = _sign(
            caller,
            startTokenId,
            deadline,
            signerPrivateKey
        );

        uint256 quantity = 1;
        uint256 cost = quantity * costPerToken;

        uint256 balanceETH0 = address(this).balance;
        uint256 balanceDynamis0 = dynamis.balanceOf(address(this));
        dynamis.mintWithETH{ value: cost }(quantity, deadline, signature);
        uint256 balanceETH1 = address(this).balance;
        uint256 balanceDynamis1 = dynamis.balanceOf(address(this));

        assertEq(balanceETH0 - cost, balanceETH1);
        assertEq(balanceDynamis1 - quantity, balanceDynamis0);

        // Testing with more than one quantity.

        caller = address(this);
        startTokenId = dynamis.totalSupply() + 1;
        signature = _sign(caller, startTokenId, deadline, signerPrivateKey);

        quantity = 10;
        cost = quantity * costPerToken;

        balanceETH0 = balanceETH1;
        balanceDynamis0 = dynamis.balanceOf(address(this));
        dynamis.mintWithETH{ value: cost }(quantity, deadline, signature);
        balanceETH1 = address(this).balance;
        balanceDynamis1 = dynamis.balanceOf(address(this));

        assertEq(balanceETH0 - cost, balanceETH1);
        assertEq(balanceDynamis1 - quantity, balanceDynamis0);

        // Testing with single quantity and excess payable cost.

        caller = address(this);
        startTokenId = dynamis.totalSupply() + 1;
        signature = _sign(caller, startTokenId, deadline, signerPrivateKey);

        quantity = 1;
        cost = (quantity * costPerToken) + 1e18;

        balanceETH0 = balanceETH1;
        balanceDynamis0 = dynamis.balanceOf(address(this));
        dynamis.mintWithETH{ value: cost }(quantity, deadline, signature);
        balanceETH1 = address(this).balance;
        balanceDynamis1 = dynamis.balanceOf(address(this));

        assertEq(balanceETH0 - (cost - 1e18), balanceETH1);
        assertEq(balanceDynamis1 - quantity, balanceDynamis0);

        // Testing with more than one quantity and excess payable cost.

        caller = address(this);
        startTokenId = dynamis.totalSupply() + 1;
        signature = _sign(caller, startTokenId, deadline, signerPrivateKey);

        quantity = 10;
        cost = (quantity * costPerToken) + 1e18;

        balanceETH0 = balanceETH1;
        balanceDynamis0 = dynamis.balanceOf(address(this));
        dynamis.mintWithETH{ value: cost }(quantity, deadline, signature);
        balanceETH1 = address(this).balance;
        balanceDynamis1 = dynamis.balanceOf(address(this));

        assertEq(balanceETH0 - (cost - 1e18), balanceETH1);
        assertEq(balanceDynamis1 - quantity, balanceDynamis0);
    }

    function test_Mint() external {
        uint256 costPerToken = 1000 * 1e6;
        uint256 deadline = block.timestamp + 1;

        // Testing with single quantity.

        address caller = address(this);
        uint256 startTokenId = dynamis.totalSupply() + 1;

        bytes memory signature = _sign(
            caller,
            startTokenId,
            deadline,
            signerPrivateKey
        );

        uint256 quantity = 1;
        uint256 cost = quantity * costPerToken;

        uint256 balanceUSDT0 = usdt.balanceOf(address(this));
        uint256 balanceDynamis0 = dynamis.balanceOf(address(this));
        usdt.approve(address(dynamis), cost);
        dynamis.mint(usdt, quantity, deadline, signature);
        uint256 balanceUSDT1 = usdt.balanceOf(address(this));
        uint256 balanceDynamis1 = dynamis.balanceOf(address(this));

        assertEq(balanceUSDT0 - cost, balanceUSDT1);
        assertEq(balanceDynamis1 - quantity, balanceDynamis0);

        // Testing with more than one quantity.

        startTokenId = dynamis.totalSupply() + 1;
        signature = _sign(caller, startTokenId, deadline, signerPrivateKey);

        quantity = 10;
        cost = quantity * costPerToken;

        balanceUSDT0 = balanceUSDT1;
        balanceDynamis0 = dynamis.balanceOf(address(this));
        usdt.approve(address(dynamis), cost);
        dynamis.mint(usdt, quantity, deadline, signature);
        balanceUSDT1 = usdt.balanceOf(address(this));
        balanceDynamis1 = dynamis.balanceOf(address(this));

        assertEq(balanceUSDT0 - cost, balanceUSDT1);
        assertEq(balanceDynamis1 - quantity, balanceDynamis0);
    }
}
