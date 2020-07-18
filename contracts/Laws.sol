pragma solidity ^0.5.1;

import './DataStructures.sol';

contract Laws {

    DataStructures.JudiciaryEmployeeData[] public judiciaryEmployees;

    uint64 public dollarToWeiConversion = 5000000000000000;

    uint8 public withdrawalFeePercent = 5;

    uint8 public withdrawalFinePercent = 3;

    uint public withdrawalFineMaxDays = 10;

    address payable public charitableOrganization = 0x1DfC1E4a154df46C0d9F0Bd35D8E9350A8187e28;

    constructor() public {
        judiciaryEmployees.push(DataStructures.JudiciaryEmployeeData(msg.sender));
    }

    function addJudiciaryEmployee(address judiciaryEmployee) public onlyJudiciaryEmployee {
        judiciaryEmployees.push(DataStructures.JudiciaryEmployeeData(judiciaryEmployee));
    }

    function changeDollarToWeiConversion(uint64 newDollarToWeiConversion) public onlyJudiciaryEmployee {
        dollarToWeiConversion = newDollarToWeiConversion;
    }

    function changeWithdrawalFeePercent(uint8 newWithdrawalFeePercent) public onlyJudiciaryEmployee {
        withdrawalFeePercent = newWithdrawalFeePercent;
    }

    function changeCharitableOrganization(address payable newCharitableOrganization) public onlyJudiciaryEmployee {
        charitableOrganization = newCharitableOrganization;
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
