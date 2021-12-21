// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {Ownable} from "openzeppelin-solidity/contracts/access/Ownable.sol";
import {ERC20} from "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract CrowdCover is Ownable {
    address[] public donors;
    mapping(address => uint256) public balances;
    uint256 public minimumBalance = 1000000;
    uint256 public minimumTopUp = 2500000;
    uint256 public taxFee = 5;
    uint256 public revenue;
    address public treasury;
    string public version = "0.0.4";
    address public rupiahToken = 0xF91Fbd80899f2aF8202598c4C5509DED2CA46C5e;

    constructor() {
        treasury = msg.sender;
        revenue = 0;
        totalDonation = 0;
        totalRevenue = 0;
    }

    function isValidDonor(address _address) public view returns (bool) {
        uint256 balance = balances[_address];
        return balance >= minimumBalance;
    }

    function addDonor(address _address) private {
        require(isValidDonor(_address), "Balance is not sufficient.");
        if (!containsDonor(_address)) {
            donors.push(_address);
        }
    }

    function canDonate(uint256 amount) public view returns (bool) {
        uint256 singleDonation = amount / validDonorsCount();
        if (singleDonation > minimumBalance) {
            return false;
        } else {
            return true;
        }
    }

    function tax(uint256 amount) public view returns (uint256) {
        //Default: 0.005% Fee.
        return ((amount * taxFee) / 1000);
    }

    function donate(uint256 amount, address _address) public onlyOwner {
        uint256 taxedAmount = amount + tax(amount);
        require(isValidDonor(_address), "Recipient invalid.");
        require(canDonate(taxedAmount), "There are not enough Donors.");
        //Transfer to recipient.
        ERC20(rupiahToken).transferFrom(treasury, _address, amount);
        //Add revenue to CrowdCover from tax.
        revenue += tax(amount);
        //Donors balances deduction.
        for (uint256 i = 0; i < donors.length; i++) {
            if (balances[donors[i]] >= minimumBalance) {
                balances[donors[i]] -= taxedAmount;
            }
        }

        //Update trackers
        totalRevenue += taxedAmount;
        totalDonation += amount;
        totalDonationCount++;
    }

    function deposit(uint256 amount) public {
        require(amount >= minimumTopUp, "Insufficient deposit amount.");
        ERC20(rupiahToken).transferFrom(msg.sender, treasury, amount);
        balances[msg.sender] += amount;
        addDonor(msg.sender);
    }

    function transferRevenue(uint256 amount, address _address)
        public
        onlyOwner
    {
        require(amount <= revenue);
        ERC20(rupiahToken).transferFrom(treasury, _address, amount);
    }

    //Trackers
    uint256 public totalDonation;
    uint256 public totalRevenue;
    uint256 public totalDonationCount;

    function DonorsBalance() public view returns (uint256) {
        uint256 amount = 0;
        for (uint256 i = 0; i < donors.length; i++) {
            amount += balances[donors[i]];
        }

        return amount;
    }

    function validDonorsCount() public view returns (uint256) {
        uint256 validDonors = 0;
        for (uint256 i = 0; i < donors.length; i++) {
            if (isValidDonor(donors[i])) {
                validDonors++;
            }
        }

        return validDonors;
    }

    function currentFunds() public view returns (uint256) {
        return validDonorsCount() * minimumBalance;
    }

    function totalDonorsCount() public view returns (uint256) {
        return donors.length;
    }

    //Governance
    function setMinimumBalance(uint256 amount) public onlyOwner {
        require(amount >= 100000);
        minimumBalance = amount;
    }

    function setMinimumTopUp(uint256 amount) public onlyOwner {
        require(amount >= minimumBalance);
        minimumTopUp = amount;
    }

    function setTaxFee(uint256 amount) public onlyOwner {
        require(amount >= 5);
        taxFee = amount;
        //Tax fee is divided by 1000 (eg: if tax fee is 5 then the tax is 0.005%)
    }

    //Utilities
    function containsDonor(address _address) private view returns (bool) {
        for (uint256 i = 0; i < donors.length; i++) {
            if (_address == donors[i]) {
                return true;
            }
        }

        return false;
    }
}
