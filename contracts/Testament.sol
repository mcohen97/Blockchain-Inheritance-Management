pragma solidity ^0.5.1;

contract Testament {

    address payable public owner;
    address payable[] heirs;
    uint8[] percentages;
    address payable[] managers;

    constructor(address payable[] memory _heirs, uint8[] memory _cutPercents, address payable[] memory _managers) public payable{
        require(_heirs.length > 0, "The testament must have at least one heir.");
        require(_heirs.length == _cutPercents.length, "Heirs' addresses and cut percentajes counts must be equal.");
        require(_managers.length >= 2 && _managers.length <= 5, "There can only be between 2 and 5 managers");

        owner = msg.sender;
        managers = _managers;
        heirs = _heirs;
        percentages = _cutPercents;
    }

    function destroy() public onlyOwner {
        selfdestruct(owner);
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "only the contract's owner can perform this action.");
        _;
    }
}


