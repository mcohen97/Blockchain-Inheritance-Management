pragma solidity ^0.5.1;

contract Testament {

    address payable public owner;
    address payable[] heirs;
    uint8[] percentages;
    address payable[] managers;

    constructor(address payable[] memory _heirs, uint8[] memory _cutPercents, address payable[] memory _managers) public payable{
        require(_heirs.length > 0, "The testament must have at least one heir.");
        require(_heirs.length == _cutPercents.length, "Heirs' addresses and cut percentajes counts must be equal.");
        require(managersWithinBounds(_managers.length), "There can only be between 2 and 5 managers");
        require(addUpTo100(_cutPercents), "Percentajes must add up to 100");

        owner = msg.sender;
        managers = _managers;
        heirs = _heirs;
        percentages = _cutPercents;
    }

    function destroy() public onlyOwner {
        selfdestruct(owner);
    }

    function managersWithinBounds(uint count) private pure returns (bool) {
        return count >= 2 && count <= 5;
    }

    function addUpTo100(uint8[] memory percents) private pure returns (bool) {
        uint sum = 0;
        for(uint i = 0; i < percents.length; i++){
            sum += percents[i];
        }
        return sum == 100;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "only the contract's owner can perform this action.");
        _;
    }
}


