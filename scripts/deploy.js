const hre = require("hardhat");

async function main() {
    // Checking gas price.
    const gasPriceUpperBound = process.env.GAS_PRICE_UPPER_BOUND;
    await checkGasPrice(gasPriceUpperBound);

    // Getting network name.
    const networkName = hre.network.name;
    console.log("Chain:", networkName);

    // Deployment variables.
    const ownerAddress = process.env.OWNER_ADDRESS;
    const name = process.env.NAME;
    const symbol = process.env.SYMBOL;
    const reservedCap = process.env.RESERVED_CAP;
    const launchCap = process.env.LAUNCH_CAP;
    const launchTimestamp = process.env.LAUNCH_START_TIMESTAMP;
    const pai3Address = process.env.PAI3_ADDRESS;
    const treasuryWalletAddress = process.env.TREASURY_WALLET_ADDRESS;
    const rewardWalletAddress = process.env.REWARD_WALLET_ADDRESS;
    const signerAddress = process.env.SIGNER_ADDRESS;
    const baseURI = process.env.BASE_URI;
    const phaseBaseCosts = process.env.PHASE_BASE_COSTS.split("|");
    const tokenAddresses = process.env.TOKEN_ADDRESSES.split("|");
    const priceFeedAddresses = process.env.PRICE_FEED_ADDRESSES.split("|");

    // Structuring deployment variables.
    const dynamisParams = [
        {
            owner: ownerAddress,
            name: name,
            symbol: symbol,
            reservedCap: reservedCap,
            launchCap: launchCap,
            launchStartTimestamp: launchTimestamp,
            pai3: pai3Address,
            treasuryWallet: treasuryWalletAddress,
            rewardWallet: rewardWalletAddress,
            signer: signerAddress,
            baseURI: baseURI,
            phaseBaseCosts: phaseBaseCosts,
            tokens: tokenAddresses,
            priceFeeds: priceFeedAddresses
        }
    ];

    // Deploying collections.
    const dynamisAddress = await deploy("Dynamis", dynamisParams);

    // Setting up collections.
    if (networkName === "staging" || networkName === "hardhat") {
        const pai3Instance = await hre.ethers.getContractAt("PAI3", pai3Address);

        const approvalTransaction = await pai3Instance.approve(dynamisAddress, BigInt(2 ** 256) - 1n);
        await approvalTransaction.wait(1);

        console.log("PAI3 approved for Dynamis");
    }

    // Waiting for block explorer.
    await new Promise((resolve) => setTimeout(resolve, 60000));

    // Verifying collections.
    await verify(dynamisAddress, dynamisParams);

    // Exiting.
    process.exit();
}

async function checkGasPrice(gasPriceUpperBound) {
    let feeData = await hre.ethers.provider.getFeeData();
    let gasPrice = parseFloat(hre.ethers.formatUnits(feeData.gasPrice, "gwei"));

    console.log(`Gas Price: ${gasPrice} Gwei`);

    if (gasPriceUpperBound != "" && gasPriceUpperBound != "0") {
        while (gasPrice > gasPriceUpperBound) {
            feeData = await hre.ethers.provider.getFeeData();

            if (gasPrice != hre.ethers.formatUnits(feeData.gasPrice, "gwei")) {
                gasPrice = parseFloat(hre.ethers.formatUnits(feeData.gasPrice, "gwei"));

                console.log(`Gas Price: ${gasPrice} Gwei`);
            }
        }
    }
}

async function deploy(contractName, constructorArguments) {
    const contract = await hre.ethers.deployContract(contractName, constructorArguments);
    await contract.waitForDeployment();

    const contractAddress = contract.target;
    const deploymentTxHash = await contract.deploymentTransaction().hash;
    const deploymentTx = await hre.ethers.provider.getTransactionReceipt(deploymentTxHash);
    const deploymentBlockNumber = deploymentTx.blockNumber;

    console.log(`${contractName} deployed to:`, contractAddress);
    console.log("at block number:", deploymentBlockNumber);

    return contractAddress;
}

async function verify(contractAddress, constructorArguments) {
    console.log(`verify ${contractAddress} with arguments ${constructorArguments.join(",")}`);

    try {
        await hre.run("verify:verify", { address: contractAddress, constructorArguments: constructorArguments });
    } catch (error) {
        console.log(error);
    }
}

async function verifyWithPath(contractAddress, contractPath, constructorArguments) {
    console.log(`verify ${contractAddress} with arguments ${constructorArguments.join(",")}`);

    try {
        await hre.run("verify:verify", {
            address: contractAddress,
            contract: contractPath,
            constructorArguments: constructorArguments
        });
    } catch (error) {
        console.log(error);
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
    process.exit();
});
