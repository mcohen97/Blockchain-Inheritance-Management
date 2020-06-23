pragma solidity ^0.5.1;

contract Testament {

    address payable public owner;
    address payable[] public heirs;
    uint8[] public percentages;

    address payable[] public managers;

    constructor(address payable[] memory _heirs, uint8[] memory _cutPercents,
                address payable[] memory _managers) public payable{

        require(_heirs.length > 0, "The testament must have at least one heir.");
        require(_heirs.length == _cutPercents.length, "Heirs' addresses and cut percentajes counts must be equal.");
        require(managersWithinBounds(_managers.length), "There can only be between 2 and 5 managers");
        require(addUpTo100(_cutPercents), "Percentajes must add up to 100");

        owner = msg.sender;
        setHeirs(_heirs);
        setManagers(_managers);
        percentages = _cutPercents;
    }


    function managersWithinBounds(uint count) private pure returns (bool) {
        return aboveManagersLowerLimit(count) && belowManagersUpperLimit(count);
    }

    function belowManagersUpperLimit(uint count) private pure returns (bool) {
        return count <= 5;
    }

    function aboveManagersLowerLimit(uint count) private pure returns (bool) {
        return count >= 2;
    }

    function addUpTo100(uint8[] memory percents) private pure returns (bool) {
        uint sum = 0;
        for(uint i = 0; i < percents.length; i++){
            sum += percents[i];
        }
        return sum == 100;
    }

    function setHeirs(address payable[] memory _heirs) private{
        heirs = _heirs;
    }

    function setManagers(address payable[] memory _managers) private {
        managers = _managers;
    }

    function suscribeManager(address payable newManager) public onlyOwner{
        require(belowManagersUpperLimit(managers.length + 1), "Managers maximum exceeded");
        managers.push(newManager);
    }

    function unsuscribeManager(address payable toDelete) public onlyOwner {
        require(aboveManagersLowerLimit(managers.length - 1), "Managers minimum not reached");
        for(uint8 i = 0; i < managers.length; i++) {
            if(toDelete == managers[i]){
                delete managers[i];
                i++;
                for(; i < managers.length; i++){
                    managers[i-1] = managers[i];
                }
            }
        }
        delete managers[managers.length - 1];
    }

    function destroy() public onlyOwner {
        selfdestruct(owner);
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "only the contract's owner can perform this action.");
        _;
    }
}


