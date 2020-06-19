pragma solidity ^0.5.1;


contract Testament {
    
    
    address payable public owner;
    
    uint public balance;
    
    constructor() public payable{
        owner = msg.sender;
        balance = address(this).balance;
    }
    
    function destroy() onlyOwner public{
        selfdestruct(owner);
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner, "only the contract's owner can perform this action.");
        _;
    }
}


