pragma solidity ^0.5.1;

contract Practico1 {
    address payable account1;
    address payable account2;
    address owner;
    constructor(address payable _account1, address payable _account2) public payable{
        account1 = _account1;
        account2 = _account2;
        owner = msg.sender;
    }
    modifier onlyOwner(){
        require(msg.sender == owner, "Not owner");
        _;
    }
    function split() public onlyOwner {
        uint balance = address(this).balance/2;
        account1.transfer(balance);
        account2.transfer(balance);
    }
}