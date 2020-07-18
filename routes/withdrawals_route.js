const express = require('express');
const router = express.Router();
const contractService = require('../services/contract.service');
const { default: Web3 } = require('web3');

router.post("/", async function(req, res){
  try{
    const executor = req.body.from;
    const ammount = req.body.ammount;
    const reason = req.body.reason;
    const contract = contractService.getTestamentContract();
    await contract.methods.withdraw(ammount, reason).send({
        from: executor,
        gas: 1000000
    });

    res.status(200).send(`OK`);

  }catch(error){
    res.status(500).send(`Cannot execute method: ${error.message}`);
  }
});

router.get("/", async function(req, res){
  try{
    const contract = contractService.getTestamentContract();
    let eventMethodName = 'withdrawal(address,uint256,string)';
    let account = req.body.manager;
    let filterEventMethod = web3.utils.sha3(eventMethodName);

    topics = [filterEventMethod]

    if (account != undefined) {
      let managerIndex = web3.utils.padLeft(web3.utils.toHex(account), 64);
      topics = [filterEventMethod, managerIndex]
    }
    let filters = {
      address: contract._address,
      fromBlock: "0x1",
      toBlock: "latest",
      topics: topics
    }

    let result = await web3.eth.getPastLogs(filters);
    let decoded = result.map(e => formatWithdrawalEvent(e));

    res.status(200).send(decoded);

  }catch(error){
    res.status(500).send(`Cannot execute method: ${error.message}`);
  }

});

router.post("/pay", async function(req, res){
  try{
    const executor = req.body.from;
    const ammount = req.body.ammount;
    const contract = contractService.getTestamentContract();
    await contract.methods.payDebt().send({
      from: executor,
      value: ammount
    });

    res.status(200).send(`OK`);

  }catch(error){
    res.status(500).send(`Cannot execute method: ${error.message}`);
  }
});

module.exports = router;

function formatWithdrawalEvent(event){
  let decoded = web3.eth.abi.decodeParameters(['uint256', 'string'], event.data);
  return {ammount: decoded['0'], reason: decoded['1']}
}