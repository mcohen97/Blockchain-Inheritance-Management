const express = require('express');
const router = express.Router();
const contractService = require('../services/contract.service');
const { default: Web3 } = require('web3');

router.post("/heirs", async function(req, res){
  try{
    const executor = req.body.from;
    const address = req.body.heir;
    const percent = req.body.percentage;
    const priority = req.body.priority;
    
    const contract = contractService.getContract();

    let result = await contract.methods.suscribeHeir(address, percent, priority)
      .send({
          from: executor,
          gas: 1000000
      });

    res.status(200).send('Ok');

  }catch(error){
    res.send(500).send(`Cannot execute method: ${error.message}`);
  }
});

router.get("/heirs/:pos", async function(req, res){

  try{
    const manager = req.params.pos;
    const contract = contractService.getContract();

    let result = {}
    result['heir'] = await contract.methods.heirs(manager).call();
    result['percentage'] = await contract.methods.percentages(manager).call();

    res.status(200).send(result);

  }catch(error){
    res.send(500).send(`Cannot execute method: ${error.message}`);
  }
});

router.delete("/heirs/:address", async function(req, res){
  try{
    const executor = req.body.from;
    const manager = req.params.address;
    const contract = contractService.getContract();

    let result = await contract.methods.unsuscribeHeir(manager)
      .send({
          from: executor
      });

    res.status(200).send('Ok');

  }catch(error){
    res.send(500).send(`Cannot execute method: ${error.message}`);
  }
});

module.exports = router;