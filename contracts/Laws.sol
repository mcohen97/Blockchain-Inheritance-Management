pragma solidity ^0.5.1;

import './DataStructures.sol';

contract Laws {

    DataStructures.JudiciaryEmployeeData[] public judiciaryEmployees;

    uint16 public dollarEtherConversion = 30;

    uint8 public withdrawalFeePercent = 5;

    constructor() public {
        judiciaryEmployees.push(DataStructures.JudiciaryEmployeeData(msg.sender));
    }

    function addJudiciaryEmployee(address judiciaryEmployee) public onlyJudiciaryEmployee {
        judiciaryEmployees.push(DataStructures.JudiciaryEmployeeData(judiciaryEmployee));
    }

    function changeDollarEtherConversion(uint16 newDollarEtherConversion) public onlyJudiciaryEmployee {
        dollarEtherConversion = newDollarEtherConversion;
    }

    function changeWithdrawalFeePercent(uint8 newWithdrawalFeePercent) public onlyJudiciaryEmployee {
        withdrawalFeePercent = newWithdrawalFeePercent;
    }

    modifier onlyJudiciaryEmployee() {
        require(containsJudiciaryEmployee(msg.sender), "only judiciary employees can perform this action.");
        _;
    }

    function containsJudiciaryEmployee(address a) private view returns (bool) {
        for (uint i = 0; i < judiciaryEmployees.length; i++) {
            if (a == judiciaryEmployees[i].account) {
                return true;
            }
        }
        return false;
    }
}
