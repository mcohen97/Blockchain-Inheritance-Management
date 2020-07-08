pragma solidity ^0.5.1;

import './DataStructures.sol';
import './Laws.sol';

contract Testament {

    address payable public owner;
    uint256 public lastLifeSignal;
    DataStructures.OwnerData public ownerData;

    DataStructures.HeirData[] public heirsData;

    uint8 managersPercentageFee;
    DataStructures.ManagerData[] public managers;
    DataStructures.Widthdrawal[] managersWithdrawals;

    Laws rules;

    bool private balanceVisible;

    DataStructures.Fee cancellationFee;
    DataStructures.Fee reductionFee;

    address payable orgAccount = 0x5E6ecDA6875b4Dc8e8Ea6CC3De4b4E3c73453c0a;

    constructor(address payable[] memory _heirs, uint8[] memory _cutPercents,
                address payable[] memory _managers, uint8 managerFee, uint cancelFee,
                bool cancelFeePercent, uint redFeeVal, bool redFeePercent, Laws _rules) public payable{

        require(_heirs.length > 0, "The testament must have at least one heir.");
        require(_heirs.length == _cutPercents.length, "Heirs' addresses and cut percentajes counts must be equal.");
        require(managersWithinBounds(_managers.length), "There can only be between 2 and 5 managers");
        require(addUpTo100(_cutPercents), "Percentajes must add up to 100");
        require(validFee(cancelFee, cancelFeePercent), "Invalid cancelation fee.");
        require(validFee(redFeeVal, redFeePercent), "Invalid reduction fee.");

        rules = _rules;
        owner = msg.sender;
        setHeirs(_heirs, _cutPercents);
        setManagers(_managers);
        balanceVisible = false;
        managersPercentageFee = managerFee;
        cancellationFee = DataStructures.Fee(cancelFee, !cancelFeePercent);
        reductionFee = DataStructures.Fee(redFeeVal, !redFeePercent);
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

    function validFee(uint value, bool isPercentage) private pure returns (bool){
        return !isPercentage || value <= 100;
    }

    function setHeirs(address payable[] memory _heirs, uint8[] memory _percentages) private{
        for(uint i = 0; i < _heirs.length; i++){
            heirsData.push(DataStructures.HeirData(_heirs[i], _percentages[i]));
        }
    }

    function setManagers(address payable[] memory _managers) private {
        for(uint i = 0; i < _managers.length; i++){
            managers.push(DataStructures.ManagerData(_managers[i], 0, 0, false));
        }
    }

    function getManagersCount() public view onlyNotSuspendedManager returns(uint){
        return managers.length;
    }

    function getHeirsCount() public view onlyNotSuspendedManager returns(uint){
        return heirsData.length;
    }

    function suscribeManager(address payable newManager) public onlyOwner{
        require(belowManagersUpperLimit(managers.length + 1), "Managers maximum exceeded");
        require(managersPercentageFee * (managers.length + 1) >= 100, "Managers fees combined make up 100% or more");
        managers.push(DataStructures.ManagerData(newManager, 0, 0, false));
    }

    function unsuscribeManager(address payable toDelete) public onlyOwner {
        require(aboveManagersLowerLimit(managers.length - 1), "Managers minimum not reached");
        uint len = managers.length;
        for(uint8 i = 0; i < len; i++) {
            if(toDelete == managers[i].account){
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

    function getDollarConversion() public view returns (uint16){
        return rules.dollarEtherConversion();
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

    function increaseInheritance() public payable onlyOwner{}

    function reduceInheritance(uint8 cut) public onlyOwner{
        uint balance = address(this).balance;
        uint reduction = (balance * cut) / 100;
        uint fee;
        if(reductionFee.isFixed){
            fee = reductionFee.value;
        }else{
            fee = (balance * reductionFee.value) / 100;
        }
        owner.transfer(reduction);
        orgAccount.transfer(fee);
    }

    function destroy() public onlyOwner {
        uint balance = address(this).balance;
        if(cancellationFee.isFixed){
            orgAccount.transfer(cancellationFee.value);
        }else{
            orgAccount.transfer((balance * cancellationFee.value)/100);
        }
        selfdestruct(owner);
    }

    function heartbeat() public onlyOwner{
        lastLifeSignal = now;
    }

    function claimInheritance() public returns(bool) {
        if(differenceInMonths(lastLifeSignal, now) > 6){
            liquidate();
            return true;
        }
        if(allManagersInformedDecease() && differenceInMonths(lastLifeSignal, now) > 3){
            liquidate();
            return true;
        }
        return false;
    }

    function allManagersInformedDecease() private view returns (bool){
        for(uint i = 0; i < managers.length; i++){
            if(!managers[i].hasInformedDecease){
                return false;
            }
        }
        return true;
    }

    function liquidate() private {
        uint inheritance = address(this).balance;
        uint managersCost = (inheritance * managersPercentageFee) / 100;
        
        for(uint8 i = 0; i < managers.length; i++) {
            managers[i].account.transfer(managersCost);
        }

        uint inheritanceAfterCosts = address(this).balance;

        for(uint i = 0; i < heirsData.length - 1; i++){
            heirsData[i].heir.transfer((inheritanceAfterCosts * heirsData[i].percentage)/100);
        }
        // Destruct the contract and send the remaining to the last heir.
        selfdestruct(heirsData[heirsData.length - 1].heir);
    }

    event withdrawal(address indexed _manager, uint _ammount, string _reason);

    function withdraw(uint ammount, string memory reason) public onlyNotSuspendedManager {
        address payable manager = msg.sender;
        updateManagerDebt(msg.sender, ammount);
        manager.transfer(ammount); // Hardcoded por ahora, la letra esta muy mal redactada.
        emit withdrawal(manager, ammount, reason);
        DataStructures.Widthdrawal memory newWithdrawal = DataStructures.Widthdrawal(manager, ammount, reason, now);
        managersWithdrawals.push(newWithdrawal);
    }

    function updateManagerDebt(address account, uint ammount) private{
        for(uint i = 0; i < managers.length; i++){
            if(managers[i].account == account){
                if(managers[i].debt == 0){
                    managers[i].withdrawalDate = now;
                }
                managers[i].debt += ammount;
                return;
            }
        }
    }
    

    function getInheritance() public view onlyNotSuspendedManager balanceReadAllowed returns (uint){
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

    modifier onlyNotSuspendedManager(){
        require(containsManager(msg.sender), "only the testament's managers can perform this action.");
        bool expiredDebt = checkManagerDebt(msg.sender);
        require(!expiredDebt, "this manager is suspended");
        _;
    }

    function checkManagerDebt(address account) private view returns (bool){
        for(uint i = 0; i < managers.length; i++){
            if(account != managers[i].account){
                continue;
            }
            if (managers[i].debt == 0){
                return false;
            }
            return differenceInMonths(managers[i].withdrawalDate, now) > 3;
        }
        return false;
    }

    function containsManager(address a) private view returns (bool) {
        for(uint i = 0; i < managers.length; i++){
            if(a == managers[i].account){
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

    function differenceInMonths(uint date1, uint date2) private pure returns (uint){
        uint monthSeconds = 3600 * 24 * 30;
        uint diffSeconds = date1 - date2;
        uint diffMonths = diffSeconds / monthSeconds;
        if(diffMonths < 0){
            return -diffMonths;
        }
        return diffMonths;
    }

    function belowManagersUpperLimit(uint count) private pure returns (bool) {
        return count <= 5;
    }

    function aboveManagersLowerLimit(uint count) private pure returns (bool) {
        return count >= 2;
    }
}


