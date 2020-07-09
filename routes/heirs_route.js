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
    
    const contract = contractService.getTestamentContract();

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
    const priority = req.params.pos;
    const contract = contractService.getTestamentContract();

    let result = await contract.methods.heirsData(priority).call();
    let response = {heir:result.heir, percentage: result.percentage, isDeceased: result.isDeceased}
    res.status(200).send(response);

  }catch(error){
    res.send(500).send(`Cannot execute method: ${error.message}`);
    console.log(`Cannot execute method: ${error.message}`);
  }
});

router.delete("/heirs/:address", async function(req, res){
  try{
    const executor = req.body.from;
    const heir = req.params.address;
    const contract = contractService.getTestamentContract();

    let result = await contract.methods.unsuscribeHeir(heir)
      .send({
          from: executor
      });

    res.status(200).send('Ok');

  }catch(error){
    res.send(500).send(`Cannot execute method: ${error.message}`);
  }
});

router.post("/heirs/:address/priority", async function(req, res){
  try{
    const executor = req.body.from;
    const priority = req.body.priority;
    const heir = req.params.address;
    const contract = contractService.getTestamentContract();

    let result = await contract.methods.changeHeirPriority(heir, priority)
      .send({
          from: executor
      });

    res.status(200).send('Ok');

  }catch(error){
    res.send(500).send(`Cannot execute method: ${error.message}`);
  }
});


router.post("/heirs/:address/percentage", async function(req, res){
  try{
    const executor = req.body.from;
    const percentage = req.body.percentage;
    const heir = req.params.address;
    const contract = contractService.getTestamentContract();

    let result = await contract.methods.changeHeirPercentage(heir, percentage)
      .send({
          from: executor
      });

    res.status(200).send('Ok');

  }catch(error){
    res.send(500).send(`Cannot execute method: ${error.message}`);
  }
});


module.exports = router;