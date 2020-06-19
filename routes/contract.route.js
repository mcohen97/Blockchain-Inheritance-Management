const express = require('express');
const router = express.Router();
const contractService = require('../services/contract.service');
const { default: Web3 } = require('web3');

router.get("/compile", function(req, res){
  try{
    contractService.compile();
    res.status(200).send('OK');
  }catch(error){
    res.send(500).send(new Error('Cannot compile contract'));
  }
});

router.get("/deploy", function(req, res){
  try{
    contractService.deploy();
    res.status(200).send('OK');
  }catch(error){
    res.send(500).send(new Error('Cannot deploy contract'));
  }
});

router.get("/split", async function(req, res){
  try{
    const contract = contractService.getContract();
    const accounts = await web3.eth.getAccounts();
    let result = await contract.methods.split()
      .send({
          from: accounts[0]
      });

  }catch(error){
    res.send(500).send(new Error('Cannot deploy contract'));
  }
});

module.exports = router;