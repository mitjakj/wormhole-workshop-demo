require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("hardhat-abi-exporter");
require("hardhat-contract-sizer");
require("solidity-coverage");

const { 
  privateKeyMainnet, 
  baseSepoliaRPC,
  baseScanApiKey,
  moonbaseAlpha,
  celoTestnet,
  arbitrumSepolia
} = require("./secrets.json");

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.21",
        settings: {
          evmVersion: "paris",
          // optimizer: {
          //   enabled: true,
          //   runs: 200,
          // },
          // outputSelection: {
          //   "*": {
          //     "*": [
          //       "evm.bytecode",
          //       "evm.deployedBytecode",
          //       "devdoc",
          //       "userdoc",
          //       "metadata",
          //       "abi"
          //     ]
          //   }
          // },
          // viaIR : true,
        },
      },
    ]
  },
  networks: {
    hardhat: {
      hardfork: "shanghai",
    },
    baseSepolia: {
      url: baseSepoliaRPC, 
      chainId: 84532,
      gasPrice: 100000000, // 0.1gwei
      gas: 2000000,
      accounts: [privateKeyMainnet],
      explorer: "https://sepolia.basescan.org/",
      wormholeId: 10004,
      wormholeRelayer: "0x93BAD53DDfB6132b0aC8E37f6029163E63372cEE",
    },
    moonbaseAlpha: {
      // url: "https://moonbeam-alpha.api.onfinality.io/public",
      url: "https://moonbase-alpha.public.blastapi.io",
      chainId: 1287,
      gasPrice: 5000000000, // 5gwei
      gas: 2000000,
      accounts: [privateKeyMainnet],
      explorer: "https://moonbase.moonscan.io/",
      wormholeId: 16,
      wormholeRelayer: "0x0591C25ebd0580E0d4F27A82Fc2e24E7489CB5e0",
    },
    celoTestnet: {
      url: 'https://alfajores-forno.celo-testnet.org', 
      chainId: 44787,
      gasPrice: 10000000000, // 10gwei
      gas: 2000000,
      accounts: [privateKeyMainnet],
      explorer: "https://alfajores.celoscan.io/",
      wormholeId: 14,
      wormholeRelayer: "0x306B68267Deb7c5DfCDa3619E22E9Ca39C374f84",
    },
  },
  abiExporter: {
    path: "./data/abi",
    clear: true,
    flat: true,
  },
  etherscan: {
    apiKey: {
      baseSepolia: baseScanApiKey,
      moonbaseAlpha: moonbaseAlpha,
      celoTestnet: celoTestnet,
      arbitrumSepolia: arbitrumSepolia,
    },
    customChains: [
      {
        network: "arbitrumSepolia",
        chainId: 421614,
        urls: {
          apiURL: 'https://api-sepolia.arbiscan.io/api',
          browserURL: 'https://arbiscan.io/',
        }
      },
      {
        network: "baseSepolia",
        chainId: 84532,
        urls: {
          apiURL: 'https://api-sepolia.basescan.org/api',
          browserURL: 'https://basescan.org/',
        }
      },
      {
        network: "celoTestnet",
        chainId: 44787,
        urls: {
          apiURL: "https://api-alfajores.celoscan.io/api",
          browserURL: 'https://alfajores.celoscan.io/',
        }
      }
    ]
  },
};
