pragma solidity ^0.5.1;

import './DataStructures.sol';

contract Testament {

    DataStructures structs = new DataStructures();

    address payable public owner;
    DataStructures.OwnerData public ownerData;

    DataStructures.HeirData[] public heirsData;

    address payable[] public managers;

    bool private balanceVisible;

    constructor(address payable[] memory _heirs, uint8[] memory _cutPercents,
                address payable[] memory _managers) public payable{

        require(_heirs.length > 0, "The testament must have at least one heir.");
        require(_heirs.length == _cutPercents.length, "Heirs' addresses and cut percentajes counts must be equal.");
        require(managersWithinBounds(_managers.length), "There can only be between 2 and 5 managers");
        require(addUpTo100(_cutPercents), "Percentajes must add up to 100");

        owner = msg.sender;
        setHeirs(_heirs, _cutPercents);
        setManagers(_managers);
        balanceVisible = false;
    }

    function addOwnerData(string memory _fullName, string memory _id, uint256 _birthdate,
                          string memory _homeAddress, string memory _telephone, string memory _email) public {

        ownerData = DataStructures.OwnerData(_fullName, _id, _birthdate, _homeAddress, _telephone, _email, now);
    }

    function managersWithinBounds(uint count) private pure returns (bool) {
        return aboveManagersLowerLimit(count) && belowManagersUpperLimit(count);
    }

    function addUpTo100(uint8[] memory percents) private pure returns (bool) {
        uint sum = 0;
        for(uint i = 0; i < percents.length; i++){
            sum += percents[i];
        }
        return sum == 100;
    }

    function setHeirs(address payable[] memory _heirs, uint8[] memory _percentages) private{
        for(uint i = 0; i < _heirs.length; i++){
            heirsData.push(DataStructures.HeirData(_heirs[i], _percentages[i]));
        }
    }

    function setManagers(address payable[] memory _managers) private {
        managers = _managers;
    }

    function getManagersCount() public view returns(uint){
        return managers.length;
    }

    function getHeirsCount() public view returns(uint){
        return heirsData.length;
    }

    function suscribeManager(address payable newManager) public onlyOwner{
        require(belowManagersUpperLimit(managers.length + 1), "Managers maximum exceeded");
        managers.push(newManager);
    }

    function unsuscribeManager(address payable toDelete) public onlyOwner {
        require(aboveManagersLowerLimit(managers.length - 1), "Managers minimum not reached");
        uint len = managers.length;
        for(uint8 i = 0; i < len; i++) {
            if(toDelete == managers[i]){
                delete managers[i];
                i++;
                for(; i < len; i++){
                    managers[i-1] = managers[i];
                }
            }
        }
        delete managers[len - 1];
        managers.length--;
    }

    function suscribeHeir(address payable heir, uint8 percentage, uint8 priority) public onlyOwner {
        require(priority <= heirsData.length, "Invalid priority, must be between 0 and the heirs count");
        if(priority == heirsData.length) {
            heirsData.push(DataStructures.HeirData(heir, percentage));
            adjustRestOfPercentages(priority);
            return;
        }

       uint len = heirsData.length;

       heirsData.push(heirsData[heirsData.length - 1]);

       for(uint i = len; i > priority; i--) {
            heirsData[i] = heirsData[i-1];
        }

        heirsData[priority] = DataStructures.HeirData(heir, percentage);
        adjustRestOfPercentages(priority);
    }

    function unsuscribeHeir(address payable toDelete) public onlyOwner {
        require(heirsData.length > 1, "There must be at least one heir in the testament.");
 
        uint len = heirsData.length;

        for(uint8 i = 0; i < len; i++) {
            if(toDelete == heirsData[i].heir){
                passInheritanceToOtherHeir(i);
                delete heirsData[i];
                i++;
                for(; i < len; i++){
                    heirsData[i-1] = heirsData[i];
                }
            }
        }
        delete heirsData[len - 1];
        heirsData.length--;
    }

    function passInheritanceToOtherHeir(uint8 priority) private {
        if (priority == 0){
            heirsData[1].percentage += heirsData[0].percentage;
        }else{
            heirsData[priority - 1].percentage += heirsData[priority].percentage;
        }
    }

    function changeHeirPriority(address payable heir, uint8 newPriority) public onlyOwner{

        for(uint curP = 0; curP < heirsData.length; curP++){
            if(heirsData[curP].heir == heir){
               if(curP == newPriority) return;

               DataStructures.HeirData memory toChangePriority = heirsData[curP];

               if(curP > newPriority) {
                shiftHeirsRight(newPriority, uint8(curP));
               }else{
                shiftHeirsLeft(uint8(curP), newPriority);
               }

               heirsData[newPriority] = toChangePriority;
            }
        }
    }

    function changeHeirPercentage(address payable heir, uint8 newPercentage) public onlyOwner{
        for(uint curP = 0; curP < heirsData.length; curP++){
             if(heirsData[curP].heir == heir){
                 heirsData[curP].percentage = newPercentage;
                 adjustRestOfPercentages(uint8(curP));
                 return;
             }
        }
    }

    function shiftHeirsRight(uint8 start, uint8 end) private {
        for(uint8 i = end; i > start; i--){
            heirsData[i] = heirsData[i-1];
        }
    }

    function shiftHeirsLeft(uint8 start, uint8 end) private {
        for(uint8 i = start; i < end; i++){
            heirsData[i] = heirsData[i+1];
        }
    }

    function destroy() public onlyOwner {
        selfdestruct(owner);
    }

    function getInheritance() public view onlyManager balanceReadAllowed returns (uint){
        return address(this).balance;
    }

    function allowBalanceRead(bool allowed) public onlyOwner {
        balanceVisible = allowed;
    }

    modifier balanceReadAllowed(){
        require(balanceVisible, "balance read not allowed by the testament's owner.");
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "only the contract's owner can perform this action.");
        _;
    }

    modifier onlyManager(){
        require(containsAddress(msg.sender, managers), "only the testament's managers can perform this action.");
        _;
    }

    function containsAddress(address a, address payable[] memory ls) private pure returns (bool) {
        for(uint i = 0; i < ls.length; i++){
            if(a == ls[i]){
                return true;
            }
        }
        return false;
    }

    function adjustRestOfPercentages(uint8 priority) private {
        uint8 sum = 0;
        for(uint j = 0; j < heirsData.length; j++){
            sum += heirsData[j].percentage;
        }

        int8 diff = int8(100 - sum);
        // Part to add/substract for each other heir
        int8 diffPerHeir = diff / int8(heirsData.length - 1);
        // No floats are allowed, so the remainder will be given to the first heirs, 1% to each
        int8 remander = diff % int8(heirsData.length - 1);

        if(diff > 0){
            for(uint j = 0; j < heirsData.length; j++){
                if(j == priority) continue;
                heirsData[j].percentage = uint8(int8(heirsData[j].percentage) + diffPerHeir);
                if(remander > 0){
                    heirsData[j].percentage++;
                    remander--;
                }
            }
        }else if(diff < 0){
            for(uint i = heirsData.length; i > 0; i--){
                uint j = i - 1;
                if(j == priority) continue;
                heirsData[j].percentage = uint8(int8(heirsData[j].percentage) + diffPerHeir);
                if(remander < 0){
                    heirsData[j].percentage--;
                    remander++;
                }
            }
        }

    }

    function belowManagersUpperLimit(uint count) private pure returns (bool) {
        return count <= 5;
    }

    function aboveManagersLowerLimit(uint count) private pure returns (bool) {
        return count >= 2;
    }
}


