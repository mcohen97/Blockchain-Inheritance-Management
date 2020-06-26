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

router.get("/destroy", async function(req, res){
  try{
    const contract = contractService.getContract();
    const accounts = await web3.eth.getAccounts();
    let result = await contract.methods.destroy()
      .send({
          from: accounts[0]
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

router.delete("/managers/:address", async function(req, res){
  try{
    const executor = req.body.from;
    const manager = req.params.address;
    const contract = contractService.getContract();

    let result = await contract.methods.unsuscribeManager(manager)
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