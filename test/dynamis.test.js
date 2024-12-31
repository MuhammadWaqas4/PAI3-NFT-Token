const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const hre = require("hardhat");

describe("Dynamis", function () {
    async function deploy() {
        // Getting signer.
        const signer = (await hre.ethers.getSigners())[0];

        // Token deployment variables.
        const ownerAddress = process.env.OWNER_ADDRESS;
        const rewardWalletAddress = process.env.REWARD_WALLET_ADDRESS;
        const totalSupply = process.env.TOTAL_SUPPLY;

        // Structuring token deployment variables.
        const pai3ConstructorArguments = [ownerAddress, rewardWalletAddress, totalSupply];

        // Deploying token.
        const pai3Contract = await hre.ethers.deployContract("PAI3", pai3ConstructorArguments);
        const pai3 = await pai3Contract.waitForDeployment();

        // Collection deployment variables.
        const pai3Address = pai3.getAddress();
        const feeWalletAddress = process.env.FEE_WALLET_ADDRESS;
        const signerAddress = signer.address;
        const baseURIs = process.env.BASE_URIS.split(" ");
        const tokenAddresses = process.env.TOKEN_ADDRESSES.split(" ");
        const priceFeedAddresses = process.env.PRICE_FEED_ADDRESSES.split(" ");

        // Structuring collection deployment variables.
        const dynamisConstructorArguments = [
            ownerAddress,
            pai3Address,
            feeWalletAddress,
            rewardWalletAddress,
            signerAddress,
            baseURIs[0],
            tokenAddresses,
            priceFeedAddresses
        ];

        // Deploying collection.
        const dynamisContract = await hre.ethers.deployContract("Dynamis", dynamisConstructorArguments);
        const dynamis = await dynamisContract.waitForDeployment();

        // Return variables.
        return { signer, pai3, dynamis };
    }

    it("should mint single with ETH", async function () {
        const { signer, dynamis } = await loadFixture(deploy);

        // Getting transaction and signature variables.
        const caller = signer.address;
        const startTokenId = (await dynamis.totalSupply()) + 1n;
        const quantity = 3;
        const deadline = parseInt(Date.now() / 1000);
        const value = hre.ethers.parseEther("1");

        // Message data.
        const messageDataTypes = ["address", "uint256", "uint256"];
        const messageData = [caller, startTokenId, deadline];

        // Creating message hash.
        const messageHash = hre.ethers.solidityPackedKeccak256(messageDataTypes, messageData);

        // Arrayifying message hash.
        const arrayifiedMessageHash = hre.ethers.getBytes(messageHash);

        // Getting signature.
        const signature = await signer.signMessage(arrayifiedMessageHash);

        // Sending transaction.
        await dynamis.mintWithETH(quantity, deadline, signature, { value: value });
    });

    it("should mint multiple with ETH", async function () {
        const { signer, dynamis } = await loadFixture(deploy);

        // Getting transaction and signature variables.
        const caller = signer.address;
        const startTokenId = (await dynamis.totalSupply()) + 1n;
        const quantity = 2;
        const deadline = parseInt(Date.now() / 1000);
        const value = hre.ethers.parseEther("1");

        // Message data.
        const messageDataTypes = ["address", "uint256", "uint256"];
        const messageData = [caller, startTokenId, deadline];

        // Creating message hash.
        const messageHash = hre.ethers.solidityPackedKeccak256(messageDataTypes, messageData);

        // Arrayifying message hash.
        const arrayifiedMessageHash = hre.ethers.getBytes(messageHash);

        // Getting signature.
        const signature = await signer.signMessage(arrayifiedMessageHash);

        // Sending transaction.
        await dynamis.mintWithETH(quantity, deadline, signature, { value: value });
    });
});
