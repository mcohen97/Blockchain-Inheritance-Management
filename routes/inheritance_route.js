const express = require('express');
const router = express.Router();
const contractService = require('../services/contract.service');
const { default: Web3 } = require('web3');

router.get("/", async function(req, res){
  try{
    const executor = req.body.from;
    const contract = contractService.getTestamentContract();
    let inheritance = await contract.methods.getInheritance().call({
        from: executor
    });

    res.status(200).send(`Inheritance worth: ${inheritance.total}, Current funds (considering withdrawals): ${inheritance.currentFunds}`);

  }catch(error){
    res.status(500).send(`Cannot execute method: ${error.message}`);
    console.log(`Cannot execute method: ${error.message}`);
  }
});

router.post("/increase", async function(req, res){
  try{
    const executor = req.body.from;
    const transferValue = req.body.ammount;
    const contract = contractService.getTestamentContract();
    await contract.methods.increaseInheritance().send({
        from: executor,
        value: transferValue
    });

    res.status(200).send(`Inheritance successfully increased by: ${transferValue} wei`);

  }catch(error){
    res.status(500).send(`Cannot execute method: ${error.message}`);
  }
});

router.post("/reduce", async function(req, res){
  try{
    const executor = req.body.from;
    const cut = req.body.cut;
    const contract = contractService.getTestamentContract();
    await contract.methods.reduceInheritance(cut).send({
        from: executor,
    });

    res.status(200).send(`Inheritance successfully reduced by: ${cut} percent`);

  }catch(error){
    res.status(500).send(`Cannot execute method: ${error.message}`);
  }
});

router.post("/visibility", async function(req, res){
  try{
    const executor = req.body.from;
    const allowed = req.body.value;
    const contract = contractService.getTestamentContract();
    await contract.methods.allowBalanceRead(allowed).send({
        from: executor
    });

    res.status(200).send(`OK`);

  }catch(error){
    res.status(500).send(`Cannot execute method: ${error.message}`);
  }
});

router.get("/organization_claim", async function(req, res){
  try{
    const executor = req.body.from;
    const contract = contractService.getTestamentContract();
    result = await contract.methods.claimToOrganization().send({
        from: executor
    });

    res.status(200).send('Inheritance liquidated successfully.');

  }catch(error){
    res.status(500).send(`Cannot execute method: ${error.message}`);
  }
});

router.get("/claim", async function(req, res){
  try{
    const executor = req.body.from;
    const contract = contractService.getTestamentContract();
    result = await contract.methods.claimInheritance().send({
        from: executor
    });

    response = formatClaimEvent(result.events.inheritanceClaim);
    res.status(200).send(response);

  }catch(error){
    res.status(500).send(`Cannot execute method: ${error.message}`);
  }
});

module.exports = router;

function formatClaimEvent(event){
  let values = event.returnValues;
  return {liquidated: values.liquidated, message: values.message}
}