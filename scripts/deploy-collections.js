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
    const feeWalletAddress = process.env.FEE_WALLET_ADDRESS;
    const signerAddress = process.env.SIGNER_ADDRESS;
    const baseURIs = process.env.BASE_URIS.split(" ");
    const tokenAddresses = process.env.TOKEN_ADDRESSES.split(" ");
    const priceFeedAddresses = process.env.PRICE_FEED_ADDRESSES.split(" ");

    // Common deployment variables.
    const v1ConstructorArguments = [ownerAddress, feeWalletAddress, "", tokenAddresses, priceFeedAddresses];

    // Structuring deployment variables.
    const dynamisConstructorArguments = [
        ownerAddress,
        feeWalletAddress,
        baseURIs[0],
        signerAddress,
        tokenAddresses,
        priceFeedAddresses
    ];
    const ethosConstructorArguments = structuredClone(v1ConstructorArguments);
    ethosConstructorArguments[2] = baseURIs[1];
    const mitosConstructorArguments = structuredClone(v1ConstructorArguments);
    mitosConstructorArguments[2] = baseURIs[2];
    const osmosConstructorArguments = structuredClone(v1ConstructorArguments);
    osmosConstructorArguments[2] = baseURIs[3];
    const seismosConstructorArguments = [ownerAddress, baseURIs[4]];

    // Deploying contracts.
    const dynamisAddress = await deploy("Dynamis", dynamisConstructorArguments);
    // const ethosAddress = await deploy("Ethos", ethosConstructorArguments);
    // const mitosAddress = await deploy("Mitos", mitosConstructorArguments);
    // const osmosAddress = await deploy("Osmos", osmosConstructorArguments);
    // const seismosAddress = await deploy("Seismos", seismosConstructorArguments);

    // Waiting for block explorer.
    await new Promise((resolve) => setTimeout(resolve, 60000));

    // Verifying contracts.
    await verify(dynamisAddress, dynamisConstructorArguments);
    // await verifyWithPath(ethosAddress, "contracts/collections/Ethos.sol:Ethos", ethosConstructorArguments);
    // await verifyWithPath(mitosAddress, "contracts/collections/Mitos.sol:Mitos", mitosConstructorArguments);
    // await verifyWithPath(osmosAddress, "contracts/collections/Osmos.sol:Osmos", osmosConstructorArguments);
    // await verify(seismosAddress, seismosConstructorArguments);

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
