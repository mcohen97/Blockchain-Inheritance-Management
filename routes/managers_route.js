const express = require('express');
const router = express.Router();
const contractService = require('../services/contract.service');
const utils = require('../services/utils');
const { default: Web3 } = require('web3');

router.delete("/managers/:address", async function(req, res){
  try{
    const executor = req.body.from;
    const manager = req.params.address;
    const contract = contractService.getTestamentContract();

    await contract.methods.unsuscribeManager(manager)
      .send({
          from: executor
      });

    res.status(200).send('Ok');

  }catch(error){
    res.status(500).send(`Cannot execute method: ${error.message}`);
  }
});

router.post("/managers", async function(req, res){
  try{
    const executor = req.body.from;
    const address = req.body.manager;
    const contract = contractService.getTestamentContract();

    let result = await contract.methods.suscribeManager(address)
      .send({
          from: executor
      });

    res.status(200).send('Ok');

  }catch(error){
    res.status(500).send(`Cannot execute method: ${error.message}`);
  }
});

router.get("/managers/:pos", async function(req, res){
  try{
    const executor = req.body.from;
    const manager = req.params.pos;
    const contract = contractService.getTestamentContract();

    let result = await contract.methods.getManagerInPos(manager).call({
      from: executor
    });

    let withDate = result.debt == 0 ? undefined : utils.unixToDateString(result.withdrawalDate);
    let response = {account: result.account, debt: result.debt, withdrawal_date: withDate, 
      has_informed_decease: result.hasInformedDecease}
    res.status(200).send(response);

  }catch(error){
    res.status(500).send(`Cannot execute method: ${error.message}`);
  }
});

module.exports = router;