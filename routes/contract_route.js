const express = require('express');
const router = express.Router();
const contractService = require('../services/contract.service');
const { default: Web3 } = require('web3');

router.post("/compile", function(req, res){
  try{
    contractService.compile();
    res.status(200).send('OK');
  }catch(error){
    res.send(500).send(new Error('Cannot compile contract'));
  }
});

router.post("/deploy", function(req, res){
  try{
    const body = req.body;
    contractService.deploy(body.heirs, body.percentages, body.managers);
    res.status(200).send('OK');
  }catch(error){
    res.send(500).send(new Error('Cannot deploy contract'));
  }
});

router.delete("/", async function(req, res){
  try{
    const executor = req.body.from;
    const contract = contractService.getContract();

     await contract.methods.destroy()
      .send({
          from: executor
      });

    res.status(200).send('Destroyed');

  }catch(error){
    res.send(500).send(`Cannot execute method: ${error.message}`);
  }
});

router.get("/information", async function(req, res){
  try{
    const contract = contractService.getContract();
    let managers = await contract.methods.getManagersCount().call();
    let heirs = await contract.methods.getHeirsCount().call();
    let percentages = await contract.methods.getPercentagesCount().call();
    res.status(200).send(`Managers: ${managers}, Heirs: ${heirs}, Percentages: ${percentages}`);

  }catch(error){
    res.send(500).send(`Cannot execute method: ${error.message}`);
  }
});

router.get("/inheritance", async function(req, res){
  try{
    const executor = req.body.from;
    const contract = contractService.getContract();
    let inheritance = await contract.methods.getInheritance().call({
        from: executor
    });

    res.status(200).send(`Inheritance worth: ${inheritance}`);

  }catch(error){
    res.send(500).send(`Cannot execute method: ${error.message}`);
  }
});

router.post("/inheritance/visibility", async function(req, res){
  try{
    const executor = req.body.from;
    const allowed = req.body.value;
    const contract = contractService.getContract();
    await contract.methods.allowBalanceRead(allowed).send({
        from: executor
    });

    res.status(200).send(`OK`);

  }catch(error){
    res.send(500).send(`Cannot execute method: ${error.message}`);
  }
});


module.exports = router;