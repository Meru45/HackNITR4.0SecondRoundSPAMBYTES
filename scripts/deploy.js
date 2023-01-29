const { ethers } = require("hardhat");

const main = async () => {
    //Creating contract factory meaning adding abi, provider, address, etc.
    const SupplyChainFactory = await ethers.getContractFactory("SupplyChain");

    //Deploying contract using contract factory.
    console.log("Deploying Contract...");
    const supplyChian = await SupplyChainFactory.deploy();
    await supplyChian.deployed();
    console.log(`Contract deployed at: ${supplyChian.address}`);

    //Veryfying contract.
    if (network.config.chainId === 5 && process.env.ETHERSCAN_API_KEY) {
        await supplyChian.deployTransaction.wait(6);
        await verify(supplyChian.address, []);
    }
};

const verify = async (contractAddress, args) => {
    console.log("Veryfying contract...");
    try {
        await run("verify:verify", {
            address: contractAddress,
            constructorArgumners: args,
        });
    } catch (e) {
        if (e.message.toLowerCase().includes("already verified")) {
            console.log("Already Verified!");
        } else {
            console.log(e);
        }
    }
};

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.log(error);
        process.exit(1);
    });
