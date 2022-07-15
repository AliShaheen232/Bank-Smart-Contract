// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Bank is Ownable{
    using Counters for Counters.Counter;
    Counters.Counter trasactionID;

    struct Account{
        string accountTitle;
        address  accountAddress; 
        uint accountCreationTime;
        bool delistStatus;
        bool blacklistStatus;    
        uint accountBalance;    
    }   
    struct Transaction{
        string transactionType;
        address from;
        uint amount;
        address to; 
        uint transactionTime;
    } 
    address public manager; //Some task will be done by the manager only.
    mapping (address => Account) public accounts;
    mapping (address => mapping(uint => Transaction)) public transactions;
    address payable[] private listForRandom;
    constructor(){
        manager = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    }    
    modifier onlyManager{
        require (msg.sender == manager,"only manager can perform this task.");
        _;
    }
    modifier blacklistedCLient{
       require (!accounts[msg.sender].blacklistStatus,"You're Blocklisted.");
        _;
    }
    modifier delistedCLient{
       require (!accounts[msg.sender].delistStatus,"Delisted Client.");
        _;
    }
    function managerHandler(address newManager) public onlyOwner {
        manager = newManager;
    }
    function accountCreation(string memory name, address _acountAddress) public onlyManager {
        Account memory acc;
        acc.accountTitle=name;
        acc.accountAddress =_acountAddress;
        acc.accountCreationTime=block.timestamp;
        accounts[_acountAddress] = acc;
    }
    function depositToAccount() public payable blacklistedCLient{
       require (msg.value >= 0,"Amount must be greater than 0.");
        accounts[msg.sender].accountBalance += msg.value;
        if(msg.value >= 2 ether){
            listForRandom.push(payable(msg.sender));
        }
        trasactionID.increment();
        uint newtrasactionID = trasactionID.current();
        Transaction memory trx;
        trx.transactionType = "Deposit";
        trx.from = msg.sender;
        trx.amount = msg.value;
        trx.transactionTime = block.timestamp;
        transactions[msg.sender][newtrasactionID] = trx;
    }
    function withdrawFunds(uint _amount) public blacklistedCLient payable{
       require (_amount >= 0,"Amount must be greater than 0.");
       require (accounts[msg.sender].accountBalance >= _amount,"Amount must be greater than 0.");
        accounts[msg.sender].accountBalance -= _amount;
        
        trasactionID.increment();
        uint newtrasactionID = trasactionID.current();
        Transaction memory trx;
        trx.transactionType = "Withdraw";
        trx.from = msg.sender;
        trx.amount = msg.value;
        trx.transactionTime = block.timestamp;
        transactions[msg.sender][newtrasactionID] = trx;
    }
    function transferfunds(address _to, uint _amount) public blacklistedCLient {
       require (_amount >= 0,"Amount must be greater than 0.");
       require (accounts[msg.sender].accountBalance >= _amount,"Amount must be greater than 0.");
       require (accounts[_to].accountAddress !=address(0) && !accounts[_to].blacklistStatus,"recipent is blacklistet.");

        accounts[msg.sender].accountBalance -= _amount;
        accounts[_to].accountBalance += _amount;

        trasactionID.increment();
        uint newtrasactionID = trasactionID.current();
        Transaction memory trx;
        trx.transactionType = "Transfer";
        trx.from = msg.sender;
        trx.amount = _amount;
        trx.to = _to;
        trx.transactionTime = block.timestamp;
        transactions[msg.sender][newtrasactionID] = trx;
    }
    function showBalance() public view returns(uint) {
        return accounts[msg.sender].accountBalance ;
    }
    function profile() public view returns(string memory, address, uint, bool,bool,uint){

        string memory accountTitle = accounts[msg.sender].accountTitle;
        address accountAddress = accounts[msg.sender].accountAddress;
        uint accountCreationTime = accounts[msg.sender].accountCreationTime;
        bool delistStatus = accounts[msg.sender].delistStatus;
        bool blacklistStatus = accounts[msg.sender].blacklistStatus;
        uint accountBalance = accounts[msg.sender].accountBalance;

        require(msg.sender == owner() ||msg.sender == manager||msg.sender == accountAddress);
        return(accountTitle, accountAddress, accountCreationTime, delistStatus, blacklistStatus, accountBalance);
    }
    function updateProfile(string memory _name) public blacklistedCLient{
        require(msg.sender == owner() ||msg.sender == manager||msg.sender == accounts[msg.sender].accountAddress );
        accounts[msg.sender].accountTitle=_name;
    }
    function blacklistHandler9(address _addr, bool _status) public onlyManager onlyOwner returns(bool){
       require (!accounts[_addr].delistStatus,"client is delisted.");
       accounts[_addr].blacklistStatus= _status;
       return accounts[_addr].blacklistStatus;
    }
    function delistedHandler(address payable _addr) public payable onlyManager onlyOwner returns(bool) {
        //to make client delisted, blacklisted status needs to be true.
        require (accounts[_addr].blacklistStatus,"make him blacklist with giving him warning.");

        accounts[_addr].delistStatus= true;
        _addr.transfer(accounts[_addr].accountBalance);
        accounts[_addr].accountBalance = 0;
       return accounts[_addr].delistStatus;
    }
    //manager can view which account is delisted.
    function delistedAddress (address _delistedAddress) public view returns(bool){
        return accounts[_delistedAddress].delistStatus;
    }
    // Random account address will get reward. amount of reward will sent in bank account not in wallet.
    function random() public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,listForRandom.length)));
    }
    function selectWinner() public view returns(address) {
        address winner;
        uint index;
        uint r= random();
        index= r%listForRandom.length;
        winner = listForRandom[index];
        return (winner);
    }
    function transferReward() public {
        address w = selectWinner();
        accounts[w].accountBalance += 1 ether;
    }
    //////Transaction History
    function showTRXHistory(address _addr) public view returns(Transaction memory){

    }
    function ShowTransactions(address _addr, uint tID) public view  returns(Transaction memory){
    return transactions[_addr][tID];
    }
}