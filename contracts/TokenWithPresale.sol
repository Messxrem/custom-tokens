// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyTokenWithPresale is ERC20, Ownable {
    uint public finalTotalSupply;
    uint public presaleMaxSupply;
    uint public maxUserSupply;
    uint public presaleCost1; 
    uint public presaleCost2; 

    uint public presaleCounter;
    uint public presaleStage;

    mapping(address => bool) public userIsWhitelisted;

    constructor(
        string memory name, 
        string memory symbol, 
        uint _finalTotalSupply,
        uint _presaleMaxSupply,
        uint _maxUserSupply,
        uint _presaleCost1, 
        uint _presaleCost2
    ) ERC20(name, symbol) {
        finalTotalSupply = _finalTotalSupply * 10 ** decimals();
        presaleMaxSupply = _presaleMaxSupply * 10 ** decimals();
        maxUserSupply = _maxUserSupply * 10 ** decimals();
        presaleCost1 = _presaleCost1 * 10 ** 18;
        presaleCost2 = _presaleCost2 * 10 ** 18;
    }

    function buyOnPresale() public payable {
        require(presaleStage != 0, "Presale has not started yet!");
        require(presaleStage != 3, "Presale has already ended!");

        require(userIsWhitelisted[msg.sender], "User is not whitelisted!");

        uint256 cost = presaleCost1;
        if (presaleStage == 2) cost = presaleCost2;

        uint256 amount = (msg.value * 10**decimals()) / cost;
        require(amount > 1, "Too little value!");

        require(balanceOf(msg.sender) + amount <= maxUserSupply, "User supply reached!");

        uint256 newSupply = totalSupply() + amount;
        require(newSupply <= finalTotalSupply, "Final supply reached!");

        presaleCounter += amount;
        require(presaleCounter <= presaleMaxSupply, "Final presale supply reached!");

        _mint(msg.sender, amount);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        uint256 newSupply = totalSupply() + amount * 10**decimals();
        require(newSupply <= finalTotalSupply, "Final supply reached!");
        _mint(to, amount * 10**decimals());
    }

    function setStage(uint8 _stg) external onlyOwner {
        require(_stg < 4, "Stage does not exist");
        presaleStage = _stg;
    }

    function addToWhiteList(address[] calldata users) public onlyOwner {
        for (uint i = 0; i < users.length; i++) {
            userIsWhitelisted[users[i]] = true;
        }
    }

    function withdraw() external onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}