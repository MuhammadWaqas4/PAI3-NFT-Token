const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const hre = require("hardhat");

describe("Dynamis", function () {
    async function deploy() {
        // Getting signer.
        const signer = (await hre.ethers.getSigners())[0];

        // Deployment variables.
        const ownerAddress = process.env.OWNER_ADDRESS;
        const feeWalletAddress = process.env.FEE_WALLET_ADDRESS;
        const baseURIs = process.env.BASE_URIS.split(" ");
        const signerAddress = signer.address;
        const tokenAddresses = process.env.TOKEN_ADDRESSES.split(" ");
        const priceFeedAddresses = process.env.PRICE_FEED_ADDRESSES.split(" ");

        // Structuring deployment variables.
        const dynamisConstructorArguments = [
            ownerAddress,
            feeWalletAddress,
            baseURIs[0],
            signerAddress,
            tokenAddresses,
            priceFeedAddresses
        ];

        // Deploying contract.
        const dynamisContract = await hre.ethers.deployContract("Dynamis", dynamisConstructorArguments);
        const dynamis = await dynamisContract.waitForDeployment();

        // Return variables.
        return { signer, dynamis };
    }

    describe("mintWithETH", function () {
        it("should mint", async function () {
            const { signer, dynamis } = await loadFixture(deploy);

            // Getting transaction variables.
            const caller = signer.address;
            const quantity = 1;
            const deadline = 2000000000;
            const value = hre.ethers.parseEther("10");

            // Message data.
            const messageDataTypes = ["address", "uint256", "uint256"];
            const messageData = [caller, quantity, deadline];

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
});
