pragma solidity ^0.5.1;

import './DataStructures.sol';
import './Laws.sol';

contract Testament {

    uint totalInheritance;
    address payable owner;
    uint256 public lastLifeSignal;
    DataStructures.OwnerData ownerData;

    DataStructures.HeirData[] heirsData;

    uint public monthInSeconds;

    uint8 managersPercentageFee;
    uint8 maxWithdrawalPercentage;
    DataStructures.ManagerData[] managers;
    DataStructures.Widthdrawal[] managersWithdrawals;
    mapping (address => uint) users; //0 - unset, 1 - owner, 2 - manager, 3 - heir

    Laws rules;

    bool private balanceVisible;

    DataStructures.Fee cancellationFee;
    DataStructures.Fee reductionFee;

    address payable orgAccount = 0x5E6ecDA6875b4Dc8e8Ea6CC3De4b4E3c73453c0a;
    uint minManagers = 2;
    uint maxManagers = 5;

    constructor(address payable[] memory _heirs, uint8[] memory _cutPercents,
                address payable[] memory _managers, uint8 managerFee, uint cancelFee,
                bool cancelFeePercent, uint redFeeVal, bool redFeePercent, uint8 managerMaxWithdraw, Laws _rules) public payable {

        require(_heirs.length > 0, "The testament must have at least one heir.");
        require(_heirs.length == _cutPercents.length, "Heirs' addresses and cut percentajes counts must be equal.");
        require(managersWithinBounds(_managers.length), "There can only be between 2 and 5 managers");
        require(addUpTo100(_cutPercents), "Percentages must add up to 100");
        require(validFee(cancelFee, cancelFeePercent), "Invalid cancelation fee.");
        require(validFee(redFeeVal, redFeePercent), "Invalid reduction fee.");

        rules = _rules;
        owner = msg.sender;
        users[owner] = 1;
        setHeirs(_heirs, _cutPercents);
        setManagers(_managers);
        balanceVisible = false;
        managersPercentageFee = managerFee;
        maxWithdrawalPercentage = managerMaxWithdraw;

        setMonthLengthToOriginal();
        lastLifeSignal = now;
        totalInheritance = msg.value;
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

    function getHeirInPos(uint8 pos) public view onlyNotSuspendedManager returns(address account, uint8 percentage, bool isDead) {
     DataStructures.HeirData memory heir = heirsData[pos];
     return (heir.heir, heir.percentage, heir.isDeceased);
    }

    function getManagerInPos(uint8 pos) public view onlyNotSuspendedManager returns(address account, uint debt,
                                                                                    uint256 withdrawalDate, bool hasInformedDecease) {
     DataStructures.ManagerData memory manager = managers[pos];
     return (manager.account, manager.debt, manager.withdrawalDate, manager.hasInformedDecease);
    }

    function getInheritance() public view onlyNotSuspendedManager balanceReadAllowed returns (uint total, uint currentFunds) {
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

    function setHeirs(address payable[] memory _heirs, uint8[] memory _percentages) private {
        for(uint i = 0; i < _heirs.length; i++){
            if(users[_heirs[i]]==0){
                heirsData.push(DataStructures.HeirData(_heirs[i], _percentages[i], false));
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
        require(managersPercentageFee * (managers.length + 1) <= 100, "Managers fees combined make up 100% or more");
        require(users[newManager]==0, "Invalid manager, selected address already has another role");
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
        require(users[heir]==0, "Invalid heir, selected address already has another role");
        users[heir] = 3;
        if(priority == heirsData.length) {
            heirsData.push(DataStructures.HeirData(heir, percentage, false));
            adjustRestOfPercentages(priority);
            return;
        }
        uint len = heirsData.length;
        heirsData.push(heirsData[heirsData.length - 1]);
        for(uint i = len; i > priority; i--) {
            heirsData[i] = heirsData[i-1];
        }
        heirsData[priority] = DataStructures.HeirData(heir, percentage, false);
        adjustRestOfPercentages(priority);
    }

    function unsuscribeHeir(address payable toDelete) public onlyOwner {
        require(heirsData.length > 1, "There must be at least one heir in the testament.");

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

    function passInheritanceToOtherHeir(uint priority) private {
        if (priority == 0){
            passToNextHeir(priority);
        }else{
            bool foundPrevious = passToPreviousHeir(priority);
            if(!foundPrevious){
                passToNextHeir(priority);
            }
        }
    }

    function passToPreviousHeir(uint8 priority) private returns(bool){
        for (uint i = priority-1; i >= 0; i--) {
            DataStructures.HeirData memory heirToPassTo = heirsData[i];
            if (isEligibleHeir(heirToPassTo)) {
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
                if (isEligibleHeir(heirToPassTo)) {
                    heirsData[i].percentage += percentageToAssign;
                    return;
                }
            }
        }
    }


    function changeHeirPriority(address payable heir, uint8 newPriority) public onlyOwner {
        uint curP = getHeirPos(heir);
        if(curP == newPriority) return;
        DataStructures.HeirData memory toChangePriority = heirsData[curP];
        
        if(curP > newPriority) {
            shiftHeirsRight(newPriority, uint8(curP));
        }else{
            shiftHeirsLeft(uint8(curP), newPriority);
        }
        heirsData[newPriority] = toChangePriority;
    }

    function changeHeirPercentage(address payable heir, uint8 newPercentage) public onlyOwner {
        require(newPercentage <= 100, "The new percentage exceeds 100%");
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

    function payDebt() public payable onlyManager{
        uint pos = getManagerPos(msg.sender);
        DataStructures.ManagerData memory manager = managers[pos];
        bool suspended = hasExpiredDebt(manager);
        if(suspended){
            uint fine = calculateWithdrawalFine(manager);
            require( msg.value >= (manager.debt + fine),
            "The payment must make up to what the manager owes, plus the fine");
        }

        if(manager.debt < msg.value){ // If you payed more that you owed, it's your problem.
            managers[pos].debt = 0;
        } else {
            managers[pos].debt -= msg.value;
        }
    }

    function calculateWithdrawalFine(DataStructures.ManagerData memory manager) private view returns(uint){
        uint finePerDay = manager.debt * rules.withdrawalFinePercent() / 100;
        uint debtDays = differenceInDays(manager.withdrawalDate, now);
        return finePerDay * max(debtDays, rules.withdrawalFineMaxDays());
    }

    function max(uint a, uint b) private pure returns(uint){
        if(a >= b){
            return a;
        }
        return b;
    }

    function reduceInheritance(uint8 cut) public onlyOwner {
        uint reduction = (totalInheritance * cut) / 100;
        require(cut <= 100, "Invalid percentage");
        require(reduction <= address(this).balance, "There are not enought funds currently.");
        uint fee;
        if(reductionFee.isFixed){
            fee = reductionFee.value;
        }else{
            fee = (totalInheritance * reductionFee.value) / 100;
        }
        owner.transfer(reduction);
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

    event inheritanceClaim(bool liquidated, string message);

    function claimInheritance() public {
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
        emit inheritanceClaim(false, message);
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
        require(differenceInMonths(lastLifeSignal, now) > 36, "36 months haven't passed for the organization to claim the funds");
        emit inheritanceClaim(true, "Contract liquidated by the organization.");
        selfdestruct(orgAccount);
    }

    function liquidate() private {
        uint managersCost = (totalInheritance * managersPercentageFee) / 100;

        for(uint8 i = 0; i < managers.length; i++) {
            managers[i].account.transfer(managersCost);
        }

        uint inheritanceAfterCosts = address(this).balance;

        bool eligibleHeirsAvailable = false;
        for (uint i = 0; i < heirsData.length - 1; i++) {
            DataStructures.HeirData memory heirToTransferTo = heirsData[i];
            if (isEligibleHeir(heirToTransferTo)) {
                eligibleHeirsAvailable = true;
                heirToTransferTo.heir.transfer((inheritanceAfterCosts * heirsData[i].percentage)/100);
            }
        }

        if (!eligibleHeirsAvailable) {
            rules.charitableOrganization().transfer(inheritanceAfterCosts);
        }
        emit inheritanceClaim(true, "Contract liquidated successfully.");
        // Destruct the contract and send the remaining to the last heir.
        selfdestruct(heirsData[heirsData.length - 1].heir);
    }

    function isEligibleHeir(DataStructures.HeirData memory heir) private pure returns(bool) {
        return !heir.isDeceased;
    }

    event withdrawal(address indexed _manager, uint _ammount, string _reason);

    function withdraw(uint256 ammount, string memory reason) public onlyNotSuspendedManager {
        address payable manager = msg.sender;
        updateManagerDebt(msg.sender, ammount);
        uint withdrawalFee = calculateWithdrawalFee(ammount);
        manager.transfer(ammount - withdrawalFee);
        orgAccount.transfer(withdrawalFee);
        emit withdrawal(manager, ammount, reason);
        DataStructures.Widthdrawal memory newWithdrawal = DataStructures.Widthdrawal(manager, ammount, reason, now);
        managersWithdrawals.push(newWithdrawal);
    }

    function calculateWithdrawalFee(uint ammount) private view returns(uint){
        uint8 percent = rules.withdrawalFeePercent();
        return (ammount * percent) / 100;
    }

    function updateManagerDebt(address account, uint ammount) private{
        uint i = getManagerPos(account);
        require(!exceedsAllowedPercentage(managers[i].debt, ammount), "Cannot withdraw this ammount, exceeds limit");
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
        bool expiredDebt = isManagerDebtExpired(msg.sender);
        require(!expiredDebt, "this manager is suspended");
        _;
    }

    modifier onlyManager(){
        require(containsManager(msg.sender), "only the testament's managers can perform this action.");
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
        return manager.debt > 0 && differenceInMonths(manager.withdrawalDate, now) > 3;
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

    function differenceInMonths(uint date1, uint date2) public view returns (uint){
        int diffSeconds = int(date2) - int(date1);
        int diffMonths = diffSeconds / int(monthInSeconds);
        if(diffMonths < 0){
            return uint(-diffMonths);
        }
        return uint(diffMonths);
    }

    function differenceInDays(uint date1, uint date2) public pure returns (uint){
        int dayInSeconds = 3600 * 24;
        int diffSeconds = int(date2 - date1);
        int diffDays = diffSeconds / dayInSeconds;
        if(diffDays < 0){
            return uint(-diffDays);
        }
        return uint(diffDays);
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

    function setMonthLengthToOriginal() public {
        monthInSeconds = 3600 * 24 * 30; // 30 days months in seconds.
    }

    function setMonthLengthTo1Minute() public onlyNotSuspendedManager {
        monthInSeconds = 60;
    }

    function setMonthLengthTo1Second() public onlyNotSuspendedManager {
        monthInSeconds = 1;
    }
}
