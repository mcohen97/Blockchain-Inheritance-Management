pragma solidity ^0.5.1;

contract DataStructures {
    struct OwnerData {
        string fullName;
        string id;
        uint256 birthdate;
        string homeAddress;
        string telephone;
        string email;
        uint256 issueDate;
    }

    struct HeirData {
        address payable heir;
        uint8 percentage;
    }

    struct ManagerData {
        address payable account;
        bool banned;
        bool hasInformedDecease;
    }

    struct Widthdrawal{
        address payable manager;
        uint ammount;
        string reason;
        uint256 date;
    }

    struct Fee{
        uint value;
        bool isFixed;
    }
}
