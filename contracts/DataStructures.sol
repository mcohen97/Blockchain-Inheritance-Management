pragma solidity ^0.5.1;

contract DataStructures {
    struct OwnerData {
        address payable account;
        string fullName;
        string id;
        int256 birthdate; // Can and will possibly be negative.
        string homeAddress;
        string telephone;
        string email;
        uint256 issueDate;
    }

    struct HeirData {
        address payable heir;
        uint8 percentage;
        bool isDeceased;
    }

    struct ManagerData {
        address payable account;
        uint debt;
        uint256 withdrawalDate;
        bool hasInformedDecease;
    }

    struct Widthdrawal {
        address payable manager;
        uint ammount;
        string reason;
        uint256 date;
    }

    struct Fee {
        uint value;
        bool isFixed;
    }

    struct JudiciaryEmployeeData {
        address account;
    }
}
