const express = require('express');
const router = express.Router();
const contractService = require('../services/contract.service');
const { default: Web3 } = require('web3');

router.delete("/managers/:address", async function(req, res){
  try{
    const executor = req.body.from;
    const manager = req.params.address;
    const contract = contractService.getContract();

    await contract.methods.unsuscribeManager(manager)
      .send({
          from: executor
      });

    res.status(200).send('Ok');

  }catch(error){
    res.send(500).send(`Cannot execute method: ${error.message}`);
  }
});

router.post("/managers", async function(req, res){
  try{
    const executor = req.body.from;
    const address = req.body.manager;
    const contract = contractService.getContract();

    let result = await contract.methods.suscribeManager(address)
      .send({
          from: executor
      });

    res.status(200).send('Ok');

  }catch(error){
    res.send(500).send(`Cannot execute method: ${error.message}`);
  }
});

router.get("/managers/:pos", async function(req, res){
  try{
    const manager = req.params.pos;
    const contract = contractService.getContract();

    let result = await contract.methods.managers(manager).call();

    res.status(200).send(result);

  }catch(error){
    res.send(500).send(`Cannot execute method: ${error.message}`);
  }
});

module.exports = router;