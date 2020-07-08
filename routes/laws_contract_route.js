const express = require('express');
const router = express.Router();
const contractService = require('../services/contract.service');
const { default: Web3 } = require('web3');

router.post("/compile", function(req, res){
  try{
    contractService.compileLaws();
    res.status(200).send('OK');
  }catch(error){
    res.send(500).send(new Error('Cannot compile contract'));
  }
});

router.post("/deploy", function(req, res){
  try{
    const body = req.body;
    contractService.deployLaws(body.from);
    res.status(200).send('OK');
  }catch(error){
    res.send(500).send(new Error('Cannot deploy contract'));
  }
});

router.get("/dollar", async function(_, res){
    try{
      const contract = contractService.getContract();
      let result = await contract.methods.getDollarConversion().call();  
      res.status(200).send(`Conversion rate: ${result}`);
  
    }catch(error){
      res.send(500).send(`Cannot execute method: ${error.message}`);
    }
  });
  
  module.exports = router;