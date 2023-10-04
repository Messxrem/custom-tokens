//npx hardhat run scripts/deploy_token_with_liquidity.js --network local
import { ethers } from "hardhat";
import UniswapFactoryArtifact from "@uniswap/v2-core/build/UniswapV2Factory.json";
const UniswapFactoryAbi = UniswapFactoryArtifact.abi;
const provider = ethers.provider;

const WETHAddress = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
const uniswapFactoryAddress = '0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f';

const main = async () =>  {
  
  const accounts = await ethers.getSigners();

  const Factory = await ethers.getContractFactory("TokenWithLiquidity");
  const tokenContract = await Factory.deploy(
    "TokenWithLiquidity", 
    "TWL",
    1000,
    1000,
    500000,
    5
  );
  await tokenContract.deploymentTransaction()?.wait();

  const tokenAddress = tokenContract.target;
  console.log('Token deployed to', tokenAddress);

  let contractBalance = await tokenContract.balanceOf(tokenAddress);
  console.log("Contract balance: ", contractBalance);

  await tokenContract.connect(accounts[0]).addLiquidity(ethers.parseEther('1'), { value: ethers.parseEther('1') });
  const factoryUniswapFactory = new ethers.Contract(uniswapFactoryAddress, UniswapFactoryAbi, provider);
  const pairAddress = await factoryUniswapFactory.getPair(tokenAddress, WETHAddress);
  console.log("Token/WETH Pair address:", pairAddress);

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});