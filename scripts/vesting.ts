//npx hardhat run scripts/vesting.js --network local
const { ethers } = require("hardhat");
const provider = ethers.provider;

async function main() {

    const accounts = await ethers.getSigners();

    //Задеплоить токен
    const tokenContractFactory = await ethers.getContractFactory("BaseToken");
    const tokenContract = await tokenContractFactory.deploy();
    await tokenContract.deployed();

    const tokenAddress = tokenContract.target;
    console.log('My Token deployed to', tokenContract);

    //Задеплоить контракт вестинга, передав в конструктор адрес токена
    const vestingContractFactory = await ethers.getContractFactory("TokenVesting");
    const vestingContract = await vestingContractFactory.deploy(tokenContract);
    await vestingContract.deployed();

    const vestingAddress = vestingContract.address;
    console.log('My Vesting Contract deployed to', vestingAddress);

    //Задеплоить контракт пресейла, передав в конструктор адрес токена и вестинга
    const presaleContractFactory = await ethers.getContractFactory("Presale");
    const presaleContract = await presaleContractFactory.deploy(tokenContract, vestingContract);
    await presaleContract.deployed();

    const presaleAddress = presaleContract.address;
    console.log('My Presale Contract deployed to', presaleAddress);

    //Установить в контракте вестинга адрес контракта пресейла
    //setPresaleContractAddress

    await vestingContract.connect(accounts[0]).setPresaleContractAddress(presaleAddress);

    //Овнер должен отправить какое-то количество своих токенов на контракт пресейла

    await tokenContract.connect(accounts[0]).transfer(presaleAddress, ethers.utils.parseEther('5000'));

    //проверяем баланс на контракте пресейла
    const presaleContractBalance = await tokenContract.balanceOf(presaleAddress);
    console.log("Presale contract's balance: ", presaleContractBalance);

    //Покупатели покупают токен с пресейла

    await presaleContract.connect(accounts[1]).buyOnPresale({value:ethers.utils.parseEther('1')});
    await presaleContract.connect(accounts[2]).buyOnPresale({value:ethers.utils.parseEther('1')});
    await presaleContract.connect(accounts[3]).buyOnPresale({value:ethers.utils.parseEther('1')});

    //Первый докупил
    await presaleContract.connect(accounts[1]).buyOnPresale({value:ethers.utils.parseEther('1')});

    //Проверяем баланс контракта - вестинга
    const vestingContractBalance = await tokenContract.balanceOf(vestingAddress);
    console.log("Vesting contract's balance: ", vestingContractBalance);

    //Проверяем полученное расписание вестинга

    const shedule1 = await vestingContract.vestingSchedules(accounts[1].address);
    const shedule2 = await vestingContract.vestingSchedules(accounts[2].address);
    const shedule3 = await vestingContract.vestingSchedules(accounts[3].address);

    console.log("Vesting shedules: ");
    console.log(shedule1.amount, shedule1.releaseDate);
    console.log(shedule2.amount, shedule2.releaseDate);
    console.log(shedule3.amount, shedule3.releaseDate);

    //Покупатель пытается востребовать свои токены с вестинга
    try{
        await vestingContract.connect(accounts[1]).withdrow();
    }
    catch(err){
        console.log("Error1: account1 can't withdrow yet");
    }

    //Прокручиваем время вперед

    await provider.send("evm_increaseTime", [1000]);
    await provider.send("evm_mine");

    //Покупатели забирают свои токены с вестинга
    await vestingContract.connect(accounts[1]).withdrow();
    await vestingContract.connect(accounts[2]).withdrow();
    await vestingContract.connect(accounts[3]).withdrow();

    //Проверяем балансы покупателей

    const acc1Balance = await tokenContract.balanceOf(accounts[1].address);
    console.log("Acc1's balance: ", acc1Balance);

    const acc2Balance = await tokenContract.balanceOf(accounts[2].address);
    console.log("Acc2's balance: ", acc2Balance);

    const acc3Balance = await tokenContract.balanceOf(accounts[3].address);
    console.log("Acc3's balance: ", acc3Balance);


    //Первый покупатель пробует забрать второй раз
    try{
        await vestingContract.connect(accounts[1]).withdrow();
    }
    catch(err){
        console.log("Error1: account1 can't withdrow - already payed");
    }

}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});