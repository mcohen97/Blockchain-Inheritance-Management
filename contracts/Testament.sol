pragma solidity ^0.5.1;

import './DataStructures.sol';

contract Testament {

    DataStructures structs = new DataStructures();

    address payable public owner;
    DataStructures.OwnerData public ownerData;
    address payable[] public heirs;
    uint16[] public percentages;

    address payable[] public managers;

    bool private balanceVisible;

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

    function setHeirs(address payable[] memory _heirs) private{
        heirs = _heirs;
    }

    function setManagers(address payable[] memory _managers) private {
        managers = _managers;
    }

    function getManagersCount() public view returns(uint){
        return managers.length;
    }

    function getHeirsCount() public view returns(uint){
        return heirs.length;
    }

    function getPercentagesCount() public view returns(uint){
        return percentages.length;
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
        require(priority <= heirs.length, "Invalid priority, must be between 0 and the heirs count");
        if(priority == heirs.length) {
            heirs.push(heir);
            percentages.push(percentage);
            return;
        }

       uint len = heirs.length;

       uint16 sum = adjustPercentages(percentage);
       uint8 adaptedPercentage = percentage - uint8(sum - 100); // Adjust new percentage to make them all sum 100.

       heirs.push(heirs[heirs.length - 1]);
       percentages.push(percentages[percentages.length - 1]);

       for(uint i = len; i > priority; i--) {
            heirs[i] = heirs[i-1];
            percentages[i] = percentages[i-1];
        }

        heirs[priority] = heir;
        percentages[priority] = adaptedPercentage;
    }

    function unsuscribeHeir(address payable toDelete) public onlyOwner {
        require(heirs.length > 1, "There must be at least one heir in the testament.");
 
        uint len = heirs.length;

        for(uint8 i = 0; i < len; i++) {
            if(toDelete == heirs[i]){
                passInheritanceToOtherHeir(i);
                delete heirs[i];
                delete percentages[i];
                i++;
                for(; i < len; i++){
                    heirs[i-1] = heirs[i];
                    percentages[i-1] = percentages[i];
                }
            }
        }
        delete heirs[len - 1];
        heirs.length--;
        delete percentages[len - 1];
        percentages.length--;
    }

    function passInheritanceToOtherHeir(uint8 priority) private {
        if (priority == 0){
            percentages[1] += percentages[0];
        }else{
            percentages[priority - 1] += percentages[priority];
        }
    }

    function changeHeirPriority(address payable heir, uint8 newPriority) public{

        for(uint curP = 0; curP < heirs.length; curP++){
            if(heirs[curP] == heir){
               uint16 percent = percentages[curP];

               if(curP == newPriority) return;
            
               delete heirs[curP];

               if(curP > newPriority) {
                shiftHeirsRight(uint8(curP), newPriority);
               }else{
                shiftHeirsLeft(uint8(curP), newPriority);
               }

               heirs[newPriority] = heir;
               percentages[newPriority] = percent;
            }
        }
    }

    function shiftHeirsRight(uint8 from, uint8 to) private {
        for(uint8 i = to; i > from; i--){
            heirs[i] = heirs[i-1];
            percentages[i] = percentages[i-1];
        }
    }

    function shiftHeirsLeft(uint8 from, uint8 to) private {
        for(uint8 i = from; i < to; i++){
            heirs[i] = heirs[i+1];
            percentages[i] = percentages[i+1];
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

    function belowManagersUpperLimit(uint count) private pure returns (bool) {
        return count <= 5;
    }

    function aboveManagersLowerLimit(uint count) private pure returns (bool) {
        return count >= 2;
    }

    function adjustPercentages(uint8 newPercent) private returns (uint16) {
        uint8 remaining = 100 - newPercent;
        uint16 sum = newPercent;

        for(uint j = 0; j < percentages.length; j++){
            uint16 adjPercent = (percentages[j] * remaining) / 100;
            percentages[j] = uint8(adjPercent);
            sum += percentages[j];
        }

        return sum;
    }
}


