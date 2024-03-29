pragma solidity ^0.5.1;

import './DataStructures.sol';
import './Laws.sol';

contract Testament {

    uint totalInheritance;
    address payable owner;
    uint256 public lastLifeSignal;
    DataStructures.OwnerData ownerData;

    DataStructures.HeirData[] heirsData;

    uint monthInSeconds;
    uint dayInSeconds;

    uint8 managersPercentageFee;
    uint8 maxWithdrawalPercentage;
    DataStructures.ManagerData[] managers;
    DataStructures.Widthdrawal[] managersWithdrawals;
    mapping (address => uint) users; //0 - unset, 1 - owner, 2 - manager, 3 - heir

    Laws rules;

    bool private balanceVisible;

    DataStructures.Fee cancellationFee;
    DataStructures.Fee reductionFee;

    address payable orgAccount;
    uint minManagers = 2;
    uint maxManagers = 5;

    uint initialCostInDollars = 200;

    constructor(address payable[] memory _heirs, uint8[] memory _cutPercents,
                address payable[] memory _managers, uint8 managerFee, uint cancelFee,
                bool cancelFeePercent, uint redFeeVal, bool redFeePercent, uint8 managerMaxWithdraw, Laws _rules, address payable organization) public payable {

        require(address(this).balance >= (initialCostInDollars * _rules.dollarToWeiConversion()),
        "Inheritance must be greater than 200 dollars.");
        require(_heirs.length > 0, "Must have at least one heir.");
        require(_heirs.length == _cutPercents.length, "Heirs' addresses and percentajes counts must be equal.");
        require(managersWithinBounds(_managers.length), "Can only be between 2 and 5 managers");
        require(addUpTo100(_cutPercents), "Percentages must add up to 100");
        require(validFee(cancelFee, cancelFeePercent), "Invalid cancelation fee.");
        require(validFee(redFeeVal, redFeePercent), "Invalid reduction fee.");
        require(managerFee >= managerMaxWithdraw, "Max withdrawal exceeds managers fee.");

        rules = _rules;
        owner = msg.sender;
        users[owner] = 1;
        chargeInitialCost();
        setHeirs(_heirs, _cutPercents);
        setManagers(_managers);
        orgAccount = organization;
        balanceVisible = false;
        managersPercentageFee = managerFee;
        maxWithdrawalPercentage = managerMaxWithdraw;

        resetTimeDimensions();
        lastLifeSignal = now;
        totalInheritance = address(this).balance;
        cancellationFee = DataStructures.Fee(cancelFee, !cancelFeePercent);
        reductionFee = DataStructures.Fee(redFeeVal, !redFeePercent);
    }

    function addOwnerData(string memory _fullName, string memory _id, int256 _birthdate,
                          string memory _homeAddress, string memory _telephone, string memory _email) public onlyOwner {

        ownerData = DataStructures.OwnerData(msg.sender, _fullName, _id, _birthdate, _homeAddress, _telephone, _email, now);
    }

    // -------------TESTAMENT INFORMATION. ---------------------------------

    function getOwnersInformation() public view onlyNotSuspendedManager returns(address, string memory, string memory,
                                                                                int256, string memory, string memory, string memory, uint256) {
        return (ownerData.account, ownerData.fullName, ownerData.id, ownerData.birthdate,
                ownerData.homeAddress, ownerData.telephone, ownerData.email, ownerData.issueDate);
    }

    function getManagersCount() public view onlyNotSuspendedManager returns(uint) {
        return managers.length;
    }

    function getHeirsCount() public view onlyNotSuspendedManager returns(uint) {
        return heirsData.length;
    }

    /*function getWithdrawal(uint8 pos) public view onlyOwner returns(address manager, uint ammount, string memory reason){
        return (managersWithdrawals[pos].manager, managersWithdrawals[pos].ammount, managersWithdrawals[pos].reason);
    }*/ // Can't add more functions, exceeds maximum size.

    function getHeirInPos(uint8 pos) public view onlyNotSuspendedManager returns(address account, uint8 percentage,
                                                                                 bool isDead, bool hasMinorChild) {
     DataStructures.HeirData memory heir = heirsData[pos];
     return (heir.heir, heir.percentage, heir.isDeceased, heir.hasMinorChild);
    }

    function getManagerInPos(uint8 pos) public view onlyNotSuspendedManager returns(address account, uint debt,
                                                                                    uint256 withdrawalDate, bool hasInformedDecease) {
     DataStructures.ManagerData memory manager = managers[pos];
     return (manager.account, manager.debt, manager.withdrawalDate, manager.hasInformedDecease);
    }

    function getInheritance() public view onlyNotSuspendedManager returns (uint total, uint currentFunds) {
        require(balanceVisible, "Not allowed by the testament's owner.");
        return (totalInheritance, address(this).balance);
    }

    //-------------------------------------------------------------------------------
    function managersWithinBounds(uint count) private view returns (bool) {
        return minManagers <= count && count <= maxManagers;
    }

    function addUpTo100(uint8[] memory percents) private pure returns (bool) {
        uint sum = 0;
        for(uint i = 0; i < percents.length; i++){
            sum += percents[i];
        }
        return sum == 100;
    }

    function validFee(uint value, bool isPercentage) private pure returns (bool) {
        return !isPercentage || value <= 100;
    }

    function chargeInitialCost() private {
        uint amount = initialCostInDollars * rules.dollarToWeiConversion();
        orgAccount.transfer(amount);
    }

    function setHeirs(address payable[] memory _heirs, uint8[] memory _percentages) private {
        for(uint i = 0; i < _heirs.length; i++){
            if(users[_heirs[i]]==0){
                heirsData.push(DataStructures.HeirData(_heirs[i], _percentages[i], false, false));
                users[_heirs[i]] = 3;
            }
        }
    }

    function setManagers(address payable[] memory _managers) private {
        for(uint i = 0; i < _managers.length; i++){
            if(users[_managers[i]]==0){
                managers.push(DataStructures.ManagerData(_managers[i], 0, 0, false));
                users[_managers[i]] = 2;
            }
        }
    }

    function suscribeManager(address payable newManager) public onlyOwner {
        require(managers.length + 1 <= maxManagers, "Managers maximum exceeded");
        require(managersPercentageFee * (managers.length + 1) <= 100, "Managers fees combined exceed 100%");
        require(users[newManager]==0, "Invalid manager, address already has another role");
        managers.push(DataStructures.ManagerData(newManager, 0, 0, false));
        users[newManager] = 2;
    }

    function unsuscribeManager(address payable toDelete) public onlyOwner {
        uint i = getManagerPos(toDelete);
        require(minManagers <= managers.length - 1, "Managers minimum not reached");
        uint len = managers.length;
        delete managers[i];
        i++;
        for(; i < len; i++){
            managers[i-1] = managers[i];
        }
        delete managers[len - 1];
        managers.length--;
        users[toDelete] = 0;
    }

    function suscribeHeir(address payable heir, uint8 percentage, uint8 priority) public onlyOwner {
        require(priority <= heirsData.length, "Invalid priority, must be between 0 and the heirs count");
        require(users[heir]==0, "Invalid heir, address already has another role");
        users[heir] = 3;
        if(priority == heirsData.length) {
            heirsData.push(DataStructures.HeirData(heir, percentage, false, false));
            adjustRestOfPercentages(priority);
            return;
        }
        uint len = heirsData.length;
        heirsData.push(heirsData[heirsData.length - 1]);
        for(uint i = len; i > priority; i--) {
            heirsData[i] = heirsData[i-1];
        }
        heirsData[priority] = DataStructures.HeirData(heir, percentage, false, false);
        adjustRestOfPercentages(priority);
    }

    function unsuscribeHeir(address payable toDelete) public onlyOwner {
        require(heirsData.length > 1, "Must be at least one heir.");

        uint len = heirsData.length;
        uint i = getHeirPos(toDelete);

        passInheritanceToOtherHeir(i);
        delete heirsData[i];
        i++;
        for(; i < len; i++){
            heirsData[i-1] = heirsData[i];
        }
        delete heirsData[len - 1];
        heirsData.length--;
        users[toDelete] = 0;
    }

    // LOGIC THAT COVERED WHEN NEXT HEIR IS DEAD IS COMMENTED, CONTRACT WOULD EXCEED SIZE LIMIT.
    function passInheritanceToOtherHeir(uint priority) private {
        if (priority == 0){
            heirsData[1].percentage += heirsData[0].percentage;
            heirsData[0].percentage = 0;
            //passToNextHeir(priority);
        }else{
            heirsData[priority - 1].percentage += heirsData[priority].percentage;
            heirsData[priority].percentage = 0;
            /*bool foundPrevious = passToPreviousHeir(priority);
            if(!foundPrevious){
                passToNextHeir(priority);
            }*/
        }
    }

    /*function passToPreviousHeir(uint8 priority) private returns(bool){
        for (uint i = priority-1; i >= 0; i--) {
            DataStructures.HeirData memory heirToPassTo = heirsData[i];
            if (!heirToPassTo.isDeceased) {
                heirsData[i].percentage += heirsData[priority].percentage;
                heirsData[priority].percentage = 0;
                return true;
            }
        }
        return false;
    }

    function passToNextHeir(uint8 priority) private{
        uint8 percentageToAssign = heirsData[priority].percentage;
        heirsData[priority].percentage = 0;
        if(priority+1 < heirsData.length){
            for (uint i = priority+1; i < heirsData.length; i++) {
                DataStructures.HeirData memory heirToPassTo = heirsData[i];
                if (!heirToPassTo.isDeceased) {
                    heirsData[i].percentage += percentageToAssign;
                    return;
                }
            }
        }
    }*/

    function changeHeirPriority(address payable heir, uint8 newPriority) public onlyOwner {
        uint curP = getHeirPos(heir);
        if(curP == newPriority) return;
        movePriority(uint8(curP), (newPriority - 1)); // It is 0 based.
    }

    function movePriority(uint8 oldPriority, uint8 newPriority) private {
        DataStructures.HeirData memory toChangePriority = heirsData[oldPriority];
        if(oldPriority > newPriority) {
            shiftHeirsRight(newPriority, oldPriority);
        }else{
            shiftHeirsLeft(oldPriority, newPriority);
        }
        heirsData[newPriority] = toChangePriority;
    }

    function changeHeirPercentage(address payable heir, uint8 newPercentage) public onlyOwner {
        require(newPercentage <= 100, "Percentage exceeds 100%");
        uint curP = getHeirPos(heir);
        heirsData[curP].percentage = newPercentage;
        adjustRestOfPercentages(uint8(curP));
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

    function increaseInheritance() public payable onlyOwner{
        totalInheritance += msg.value;
    }

    function payDebt() public payable{
        require(containsManager(msg.sender), "Only the testament's managers can perform this action.");
        uint pos = getManagerPos(msg.sender);
        DataStructures.ManagerData memory manager = managers[pos];
        bool suspended = hasExpiredDebt(manager);
        if(suspended){
            uint fine = calculateWithdrawalFine(manager);
            require( msg.value >= (manager.debt + fine),
            "The payment must make up to debt, plus the fine");
        }

        if(manager.debt < msg.value){ // If you payed more that you owed, it's your problem.
            managers[pos].debt = 0;
        } else {
            managers[pos].debt -= msg.value;
        }
    }

    function calculateWithdrawalFine(DataStructures.ManagerData memory manager) private view returns(uint){
        uint finePerDay = manager.debt * rules.withdrawalFinePercent() / 100;
        uint debtDays = differenceInDays(now, manager.withdrawalDate) - 90; // Days of suspension 
        return finePerDay * min(debtDays, rules.withdrawalFineMaxDays());
    }

    function min(uint a, uint b) private pure returns(uint){
        if(a <= b){
            return a;
        }
        return b;
    }

    function reduceInheritance(uint8 cut) public onlyOwner {
        require(cut <= 100, "Invalid percentage");
        uint reduction = (totalInheritance * cut) / 100;
        require(reduction <= address(this).balance, "Not enought funds currently.");
        uint fee;
        if(reductionFee.isFixed){
            fee = reductionFee.value;
        }else{
            fee = (reduction * reductionFee.value) / 100;
        }
        owner.transfer(reduction - fee);
        orgAccount.transfer(fee);
        totalInheritance -= reduction;
    }

    function destroy() public onlyOwner {
        if(cancellationFee.isFixed){
            orgAccount.transfer(cancellationFee.value);
        }else{
            orgAccount.transfer((totalInheritance * cancellationFee.value)/100);
        }
        selfdestruct(owner);
    }

    function heartbeat() public onlyOwner{
        lastLifeSignal = now;
    }

    function informHeirDecease(address payable heir) public onlyNotSuspendedManager {
        uint i = getHeirPos(heir);
        heirsData[i].isDeceased = true;
        passInheritanceToOtherHeir(uint8(i));
    }

    function announceHeirMinorChild(address payable heir) public onlyNotSuspendedManager {
        uint i = getHeirPos(heir);
        heirsData[i].hasMinorChild = true;
        /* The intention was to add an extra attribute to heir that stored the original position
           and used that priority to determine the priority among heirs with child, but it couldn't
           be implemented because the contract almost exceeds the maximum size allowed, so any extra
           operation will not allow the contracts deployment.
        */
        movePriority(uint8(i), 0);
    }

    function claimInheritance() public onlyNotSuspendedManagerOrHeir {

        if(differenceInMonths(lastLifeSignal, now) > 6){
            liquidate();
        }
        bool all = allManagersInformedDecease();
        if(all && differenceInMonths(lastLifeSignal, now) > 3){
            liquidate();
        }
        string memory message = "";
        if(!all){
            message = "Not all managers informed the owners's decease, and last signal was given in less than 6 months ago";
        }else{
            message = "All managers informed the owners's decease, but 3 months haven't passed since last owner's signal";
        }
        require(false, message);
    }

    function allManagersInformedDecease() private view returns (bool) {
        for(uint i = 0; i < managers.length; i++){
            if(!managers[i].hasInformedDecease){
                return false;
            }
        }
        return true;
    }

    function informOwnerDecease() public onlyNotSuspendedManager {
        uint i = getManagerPos(msg.sender);
        managers[i].hasInformedDecease = true;
    }

    function claimToOrganization() public onlyOrganization{
        require(differenceInMonths(lastLifeSignal, now) > 36,
        "36 months haven't passed since last signal");
        selfdestruct(orgAccount);
    }

    function liquidate() private {
        uint managersCost = (totalInheritance * managersPercentageFee) / 100;

        for(uint8 i = 0; i < managers.length; i++) {
            if(managers[i].debt >= managersCost) continue; // Solved outside blockchain
            managers[i].account.transfer(managersCost - managers[i].debt); //Discount debt, which can be 0.
        }

        uint inheritanceAfterCosts = address(this).balance;

        bool eligibleHeirsAvailable = false;
        for (uint i = 0; i < heirsData.length - 1; i++) {
            DataStructures.HeirData memory heirToTransferTo = heirsData[i];
            if (!heirToTransferTo.isDeceased) {
                eligibleHeirsAvailable = true;
                heirToTransferTo.heir.transfer((inheritanceAfterCosts * heirsData[i].percentage)/100);
            }
        }

        if (!eligibleHeirsAvailable) {
            rules.charitableOrganization().transfer(inheritanceAfterCosts);
        }
        // Destruct the contract and send the remaining to the last heir.
        selfdestruct(heirsData[heirsData.length - 1].heir);
    }

    event withdrawal(address indexed _manager, uint _ammount, string _reason);

    function withdraw(uint256 ammount, string memory reason) public onlyNotSuspendedManager {
        address payable manager = msg.sender;
        updateManagerDebt(msg.sender, ammount);
        uint withdrawalFee = calculateWithdrawalFee(ammount);
        manager.transfer(ammount - withdrawalFee);
        orgAccount.transfer(withdrawalFee);
        emit withdrawal(manager, ammount, reason);
        managersWithdrawals.push(DataStructures.Widthdrawal(manager, ammount, reason));
    }

    function calculateWithdrawalFee(uint ammount) private view returns(uint){
        uint8 percent = rules.withdrawalFeePercent();
        return (ammount * percent) / 100;
    }

    function updateManagerDebt(address account, uint ammount) private{
        uint i = getManagerPos(account);
        require(!exceedsAllowedPercentage(managers[i].debt, ammount), "Withdrawal exceeds limit");
        if(managers[i].debt == 0){
            managers[i].withdrawalDate = now;
        }
        managers[i].debt += ammount;
        return;
    }

    function exceedsAllowedPercentage(uint accumDebt, uint newWithdrawal) private view returns(bool) {
        return (accumDebt + newWithdrawal) > ((totalInheritance * maxWithdrawalPercentage) / 100) ;
    }

    function allowBalanceRead(bool allowed) public onlyOwner {
        balanceVisible = allowed;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "only the contract's owner can perform this action.");
        _;
    }

    modifier onlyNotSuspendedManager(){
        require(containsManager(msg.sender), "only the testament's managers can perform this action.");
        bool expiredDebt = isManagerDebtExpired(msg.sender);
        require(!expiredDebt, "this manager is suspended");
        _;
    }

    modifier onlyNotSuspendedManagerOrHeir(){
        require((containsManager(msg.sender) && !isManagerDebtExpired(msg.sender)) ||
                containsHeir(msg.sender), "Only valid managers or heirs can perform this action.");
        _;
    }

    modifier onlyOrganization(){
        require(orgAccount == msg.sender, "Only the organization can perform this action.");
        _;
    }

    function isManagerDebtExpired(address account) private view returns (bool){
        uint i = getManagerPos(account);
        return hasExpiredDebt(managers[i]);
    }

    function hasExpiredDebt(DataStructures.ManagerData memory manager) private view returns(bool){
        return manager.debt > 0 && differenceInMonths(manager.withdrawalDate, now) > 3; // Should be 90 days, but it's easier to test.
    }

    function containsManager(address a) private view returns (bool) {
        return users[a] == 2;
    }

    function containsHeir(address a) private view returns (bool) {
        uint i = getHeirPos(a);
        return !heirsData[i].isDeceased;
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

    function differenceInMonths(uint date1, uint date2) public view returns (uint){
        return timeDiff(date1, date2, monthInSeconds);
    }

    function differenceInDays(uint date1, uint date2) public view returns (uint){
        return timeDiff(date1, date2, dayInSeconds);
    }

    function timeDiff(uint date1, uint date2, uint unit) public pure returns(uint){
        int diffSeconds = int(date2) - int(date1);
        int diffUnit = diffSeconds / int(unit);
        if(diffUnit < 0){
            return uint(-diffUnit);
        }
        return uint(diffUnit);
    }

    function getManagerPos(address account) private view returns (uint){
        for(uint i = 0; i < managers.length; i++){
            if(managers[i].account == account){
                return i;
            }
        }
        require(false, "Manager does not exist.");
    }

    function getHeirPos(address account) private view returns(uint){
        for(uint i = 0; i < heirsData.length; i++){
            if(heirsData[i].heir == account){
                return i;
            }
        }
        require(false, "Heir does not exist.");
    }

    function resetTimeDimensions() public {
        dayInSeconds = 3600 * 24;
        monthInSeconds = dayInSeconds * 30; // 30 days months in seconds.
    }

    function setMonthLengthSeconds(uint secs) public onlyNotSuspendedManager {
        monthInSeconds = secs;
    }

    function setDayLengthSeconds(uint secs) public onlyNotSuspendedManager {
        dayInSeconds = secs;
    }
}
