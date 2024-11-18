# PAI3

This repository includes the smart contracts for the PAI3 ecosystem.

## How do I get set up?

Open a terminal in your workspace and then type in the following commands to fulfil the setup requirements:

1. `git clone https://github.com/MuhammadWaqas4/pai3.git`
2. `cd pai3`
3. `npm i`

## Deployment

### Setup environment variables

Set the `URL_MAINNET`, `PRIVATE_KEY_MAINNET` and `BLOCK_EXPLORER_API_KEY_MAINNET` as environment variables for mainnet deployment on your preferred mainnet or similarly `URL_STAGING`, `PRIVATE_KEY_STAGING` and `BLOCK_EXPLORER_API_KEY_STAGING` for staging deployment on your preferred testnet.<br>
You can achieve this by first creating a file named **.env** at the root of your project. Then copy the contents of the **.env.example** file into your newly created **.env** file. Finally fill in the variables for the aforementioned network.

`URL`: This is the RPC URL of the given network. Most online resources can provide these for free.<br>
`PRIVATE_KEY`: This is the private key of your account. ***Note: For staging deployment, please use a key that does NOT have any real funds associated with it.***<br>
`BLOCK_EXPLORER_API_KEY`: This is the block explorer api key used for verification of contracts. You can get these from your account on the relevant block explorer of your chosen mainnet.

### Run the deployment script

For mainnet deployment, open a terminal at the root of your project then run the following command. This will deploy and setup all relevant contracts on your chosen mainnet:

`npm run deploy`

For staging deployment, run the following command. This will deploy and setup all relevant contracts on your chosen testnet:

`npm run deploy-staging`
