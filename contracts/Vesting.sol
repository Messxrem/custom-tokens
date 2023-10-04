// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenVesting is Ownable {
    address public tokenAddress;
    address public presaleContractAddress;

    struct VestingSchedule {
        uint256 releaseDate;
        uint256 amount;
        bool withdrowed;
    }

    mapping(address => VestingSchedule) public vestingSchedules;

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    function createVestingSchedule(
        address _beneficiary,
        uint256 _releaseDate,
        uint256 _amount
    ) public onlyOwnerOrAuthorizedContract {
        uint256 amount = _amount;
        if (
            vestingSchedules[_beneficiary].amount > 0 &&
            vestingSchedules[_beneficiary].withdrowed == false
        ) {
            amount += vestingSchedules[_beneficiary].amount;
        }
        emit newVestingSheduleCreated(_beneficiary, _releaseDate, amount);
        vestingSchedules[_beneficiary] = VestingSchedule(
            _releaseDate,
            amount,
            false
        );
    }

    function withdrow() external {
        require(
            block.timestamp > vestingSchedules[msg.sender].releaseDate,
            "To early!"
        );
        require(vestingSchedules[msg.sender].amount > 0, "Nothing to pay!");
        require(
            vestingSchedules[msg.sender].withdrowed == false,
            "Already paid!"
        );

        vestingSchedules[msg.sender].withdrowed = true;
        emit tokensWithdrowed(msg.sender, vestingSchedules[msg.sender].amount);
        ERC20 token = ERC20(tokenAddress);
        token.transfer(msg.sender, vestingSchedules[msg.sender].amount);
    }

    function setPresaleContractAddress(address newContractAddress)
        external
        onlyOwner
    {
        presaleContractAddress = newContractAddress;
    }

    modifier onlyOwnerOrAuthorizedContract() {
        require(
            _msgSender() == owner() || _msgSender() == presaleContractAddress,
            "Caller is not the owner or authorized contract"
        );
        _;
    }

    event newVestingSheduleCreated(
        address beneficiary,
        uint256 releaseDate,
        uint256 amount
    );
    event tokensWithdrowed(address beneficiary, uint256 amount);
}