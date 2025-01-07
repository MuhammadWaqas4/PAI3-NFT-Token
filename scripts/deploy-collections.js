const hre = require("hardhat");

async function main() {
    // Checking gas price.
    const gasPriceUpperBound = process.env.GAS_PRICE_UPPER_BOUND;
    await checkGasPrice(gasPriceUpperBound);

    // Getting network name.
    const networkName = hre.network.name;
    console.log("Chain:", networkName);

    // Deployment variables.
    const deployments = [
        // 0, // Dynamis
        // 1, // Ethos
        2, // Mitos
        3, // Osmos
        4 // Seismos
    ];

    const ownerAddress = process.env.OWNER_ADDRESS;
    const names = process.env.NAMES.split(" ");
    const symbols = process.env.SYMBOLS.split(" ");
    const rewardDurations = process.env.REWARD_DURATIONS.split(" ");
    const rewardPerSeconds = process.env.REWARD_PER_SECONDS.split(" ");
    const baseCostSingles = process.env.BASE_COST_SINGLES.split(" ");
    const pai3Address = process.env.PAI3_ADDRESS;
    const feeWalletAddress = process.env.FEE_WALLET_ADDRESS;
    const rewardWalletAddress = process.env.REWARD_WALLET_ADDRESS;
    const signerAddress = process.env.SIGNER_ADDRESS;
    const baseURIs = process.env.BASE_URIS.split(" ");
    const tokenAddresses = process.env.TOKEN_ADDRESSES.split(" ");
    const priceFeedAddresses = process.env.PRICE_FEED_ADDRESSES.split(" ");
    const initialCap = process.env.INITIAL_CAP;
    const caps = process.env.CAPS.split(" ");

    // Common deployment variables.
    const params = {
        owner: ownerAddress,
        name: "",
        symbol: "",
        rewardDuration: "",
        rewardPerSecond: "",
        baseCostSingle: "",
        pai3: pai3Address,
        feeWallet: feeWalletAddress,
        rewardWallet: rewardWalletAddress,
        signer: signerAddress,
        baseURI: "",
        tokens: tokenAddresses,
        priceFeeds: priceFeedAddresses
    };
    const paramsAlt = {
        owner: ownerAddress,
        name: "",
        symbol: "",
        baseURI: ""
    };

    const baseV2Params = {
        params: params,
        initialCap: initialCap,
        cap: ""
    };
    const baseV1Params = {
        params: params,
        cap: ""
    };
    const baseAltParams = {
        params: paramsAlt
    };

    // Structuring deployment variables.
    const defaultParams = [baseV2Params, baseV1Params, baseV1Params, baseV1Params, baseAltParams];
    const collectionParams = defaultParams.map((value, index) => {
        let result = structuredClone(value);

        if (value !== baseAltParams) {
            result.params.rewardDuration = rewardDurations[index];
            result.params.rewardPerSecond = rewardPerSeconds[index];
            result.params.baseCostSingle = baseCostSingles[index];
            result.cap = caps[index];
        }

        result.params.name = names[index];
        result.params.symbol = symbols[index];
        result.params.baseURI = baseURIs[index];

        result = Object.values(result);

        return result;
    });

    // Deploying collections.
    const collectionAddresses = [];
    const collectionNames = [];

    for (let i = 0; i < deployments.length; i++) {
        const index = deployments[i];

        collectionNames.push(collectionParams[index][0].name);

        collectionAddresses.push(await deploy(collectionNames[i], collectionParams[index]));
    }

    // Setting up collections.
    if (networkName === "staging" || networkName === "hardhat") {
        const pai3Instance = await hre.ethers.getContractAt("PAI3", pai3Address);

        for (let i = 0; i < collectionAddresses.length; i++) {
            const index = deployments[i];

            if (defaultParams[index] !== baseAltParams) {
                const approvalTransaction = await pai3Instance.approve(collectionAddresses[i], BigInt(2 ** 256) - 1n);
                await approvalTransaction.wait(1);

                const name = collectionNames[i];

                console.log(`PAI3 approved for ${name}`);
            }
        }
    }

    // Waiting for block explorer.
    await new Promise((resolve) => setTimeout(resolve, 60000));

    // Verifying collections.
    for (let i = 0; i < collectionAddresses.length; i++) {
        let index = deployments[i];

        if (defaultParams[index] === baseV1Params) {
            const name = collectionNames[i];

            await verifyWithPath(
                collectionAddresses[i],
                `contracts/collections/${name}.sol:${name}`,
                collectionParams[index]
            );
        } else {
            await verify(collectionAddresses[i], collectionParams[index]);
        }
    }

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
