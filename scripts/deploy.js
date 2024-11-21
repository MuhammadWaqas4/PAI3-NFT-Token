const hre = require("hardhat");

async function main() {
    // Checking gas price.
    const gasPriceUpperBound = process.env.GAS_PRICE_UPPER_BOUND;
    await checkGasPrice(gasPriceUpperBound);

    // Getting network name.
    const networkName = hre.network.name;
    console.log("Chain:", networkName);

    // Deployment variables.
    const ownerAddress = "0x45faf7923BAb5A5380515E055CA700519B3e4705";
    const baseURI = "ipfs://QmaTgKeRjRfk9yAjshdLoYShYyJDsRwABy8f6pDj32jkEo/";
    const feeWalletAddress = "0x45faf7923BAb5A5380515E055CA700519B3e4705";
    ("");
    const tokenAddresses = ["0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"];
    const priceFeedAddresses = ["0x694AA1769357215DE4FAC081bf1f309aDC325306"];

    // Deploying contracts.
    const dynamisAddress = await deploy("Dynamis", [
        ownerAddress,
        baseURI,
        feeWalletAddress,
        tokenAddresses,
        priceFeedAddresses
    ]);
    const ethosAddress = await deploy("Ethos", [
        ownerAddress,
        baseURI,
        feeWalletAddress,
        tokenAddresses,
        priceFeedAddresses
    ]);
    const mitosAddress = await deploy("Mitos", [
        ownerAddress,
        baseURI,
        feeWalletAddress,
        tokenAddresses,
        priceFeedAddresses
    ]);
    const osmosAddress = await deploy("Osmos", [
        ownerAddress,
        baseURI,
        feeWalletAddress,
        tokenAddresses,
        priceFeedAddresses
    ]);
    const seismosAddress = await deploy("Seismos", [ownerAddress, baseURI]);

    // Waiting for block explorer.
    await new Promise((resolve) => setTimeout(resolve, 60000));

    // Verifying contracts.
    await verify(dynamisAddress, [ownerAddress, baseURI, feeWalletAddress, tokenAddresses, priceFeedAddresses]);
    await verify(ethosAddress, [ownerAddress, baseURI, feeWalletAddress, tokenAddresses, priceFeedAddresses]);
    await verify(mitosAddress, [ownerAddress, baseURI, feeWalletAddress, tokenAddresses, priceFeedAddresses]);
    await verify(osmosAddress, [ownerAddress, baseURI, feeWalletAddress, tokenAddresses, priceFeedAddresses]);
    await verify(seismosAddress, [ownerAddress, baseURI]);

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
