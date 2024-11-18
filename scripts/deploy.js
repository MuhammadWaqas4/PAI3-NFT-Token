const hre = require("hardhat");

async function main() {
    // Checking gas price.
    const gasPriceUpperBound = process.env.GAS_PRICE_UPPER_BOUND;
    await checkGasPrice(gasPriceUpperBound);

    // Getting network name.
    const networkName = hre.network.name;
    console.log("Chain:", networkName);

    // Deployment variables.
    let ownerAddress, fundsWalletAddress, usdtAddress, ethPriceFeedAddress, baseURI;

    // Setting deployment variables.
    if (networkName == "staging") {
        ownerAddress = "";
        fundsWalletAddress = "";
        usdtAddress = "";
        ethPriceFeedAddress = "";
        baseURI = "";
    } else if (networkName == "mainnet") {
        ownerAddress = "";
        fundsWalletAddress = "";
        usdtAddress = "";
        ethPriceFeedAddress = "";
        baseURI = "";
    }

    // Deploying contracts.
    const paiAddress = await deploy("PAI", [ownerAddress]);

    // Setting up contracts.
    const paiInstance = await hre.ethers.getContractAt("PAI", paiAddress);

    // Waiting for block explorer.
    await new Promise((resolve) => setTimeout(resolve, 60000));

    // Verifying contracts.
    await verify(paiAddress, [ownerAddress]);

    // Exiting.
    process.exit();
}

async function checkGasPrice(gasPriceUpperBound) {
    let feeData = await hre.ethers.provider.getFeeData();
    let gasPrice = hre.ethers.formatUnits(feeData.gasPrice, "gwei");
    console.log("Gas Price:", gasPrice, "Gwei");

    while (gasPrice > gasPriceUpperBound) {
        feeData = await hre.ethers.provider.getFeeData();

        if (gasPrice != hre.ethers.formatUnits(feeData.gasPrice, "gwei")) {
            gasPrice = hre.ethers.formatUnits(feeData.gasPrice, "gwei");
            console.log("Gas Price:", gasPrice, "Gwei");
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

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
    process.exit();
});
