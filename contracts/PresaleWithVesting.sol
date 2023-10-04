// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ITokenVesting {
    function createVestingSchedule(
        address _beneficiary,
        uint256 _releaseDate,
        uint256 _amount
    ) external;
}

contract Presale is Ownable {
    uint256 public immutable presaleCost = 0.05 ether; //cost1 for 1 * 10 ** decimals()
    uint256 public counter = 1;

    address public tokenAddress;
    address public vestingContractAddress;

    constructor(address _tokenContractAddress, address _vestingContractAddress) {
        tokenAddress = _tokenContractAddress;
        vestingContractAddress = _vestingContractAddress; 
    }

    function buyOnPresale() public payable {
        uint256 amount = (msg.value * 10**18) / presaleCost;
        require(amount > 1, "Too little value!");

        uint256 releaseDate = block.timestamp + counter * 60;
        counter += 1;

        ERC20 token = ERC20(tokenAddress);
        token.transfer(vestingContractAddress, amount);

        ITokenVesting(vestingContractAddress).createVestingSchedule(
            msg.sender,
            releaseDate,
            amount
        );
    }

    function setVestingContractAddress(address newContractAddress) external onlyOwner {
        vestingContractAddress = newContractAddress;
    }

    function withdrawMoney() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function withdrawTokens() public onlyOwner {
        ERC20 token = ERC20(tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}