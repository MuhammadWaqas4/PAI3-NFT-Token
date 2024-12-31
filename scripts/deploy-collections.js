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
    const pai3Address = process.env.PAI3_ADDRESS;
    const feeWalletAddress = process.env.FEE_WALLET_ADDRESS;
    const rewardWalletAddress = process.env.REWARD_WALLET_ADDRESS;
    const signerAddress = process.env.SIGNER_ADDRESS;
    const baseURIs = process.env.BASE_URIS.split(" ");
    const tokenAddresses = process.env.TOKEN_ADDRESSES.split(" ");
    const priceFeedAddresses = process.env.PRICE_FEED_ADDRESSES.split(" ");

    // Common deployment variables.
    const baseConstructorArguments = {
        owner: ownerAddress,
        pai3: pai3Address,
        feeWallet: feeWalletAddress,
        rewardWallet: rewardWalletAddress,
        signer: signerAddress,
        baseURI: "",
        token: tokenAddresses,
        priceFeed: priceFeedAddresses
    };
    const baseSimpleConstructorArguments = {
        owner: ownerAddress,
        baseURI: ""
    };

    // Structuring deployment variables.
    const collectionContractNames = ["Dynamis", "Ethos", "Mitos", "Osmos", "Seismos"];
    let collectionConstructorArguments = [
        baseConstructorArguments,
        baseConstructorArguments,
        baseConstructorArguments,
        baseConstructorArguments,
        baseSimpleConstructorArguments
    ];
    collectionConstructorArguments = collectionConstructorArguments.map((value, index) => {
        value = structuredClone(value);
        value.baseURI = baseURIs[index];
        value = Object.values(value);
        return value;
    });

    // Deploying collections.
    const collectionAddresses = [];
    for (let i = 0; i < collectionContractNames.length; i++) {
        collectionAddresses.push(await deploy(collectionContractNames[i], collectionConstructorArguments[i]));
    }

    // Setting up collections.
    if (networkName === "staging") {
        const pai3Instance = await hre.ethers.getContractAt("PAI3", pai3Address);

        for (let i = 0; i < collectionAddresses.length; i++) {
            const approvalTransaction = await pai3Instance.approve(collectionAddresses[i], BigInt(2 ** 256) - 1n);
            await approvalTransaction.wait(1);
        }
    }

    // Waiting for block explorer.
    await new Promise((resolve) => setTimeout(resolve, 60000));

    // Verifying collections.
    for (let i = 0; i < collectionAddresses.length; i++) {
        await verify(collectionAddresses[i], collectionConstructorArguments[i]);
    }

    // Exiting.
    process.exit();
}

async function checkGasPrice(gasPriceUpperBound) {
    let feeData = await hre.ethers.provider.getFeeData();
    let gasPrice = parseFloat(hre.ethers.formatUnits(feeData.gasPrice, "gwei"));
    console.log("Gas Price:", gasPrice, "Gwei");

    if (gasPriceUpperBound != "" && gasPriceUpperBound != "0") {
        while (gasPrice > gasPriceUpperBound) {
            feeData = await hre.ethers.provider.getFeeData();

            if (gasPrice != hre.ethers.formatUnits(feeData.gasPrice, "gwei")) {
                gasPrice = parseFloat(hre.ethers.formatUnits(feeData.gasPrice, "gwei"));
                console.log("Gas Price:", gasPrice, "Gwei");
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
