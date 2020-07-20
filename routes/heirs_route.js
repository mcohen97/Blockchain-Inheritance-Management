const express = require('express');
const router = express.Router();
const contractService = require('../services/contract_service');
const { default: Web3 } = require('web3');


router.get("/heirs/", async function(req, res){
  try{
    const executor = req.body.from;
    
    const contract = contractService.getTestamentContract();

    let heirsCount = await contract.methods.getHeirsCount().call({
      from: executor
    });

    let heirs = [];
    for (let i = 0; i < heirsCount; i++) {
      let heir = await contract.methods.getHeirInPos(i).call({
        from: executor
      });
      heirs.push(formatHeirResult(heir, i));
    }

    res.status(200).send(heirs);

  }catch(error){
    res.status(500).send(`Cannot execute method: ${error.message}`);
  }
});

router.post("/heirs/", async function(req, res){
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
    res.status(500).send(`Cannot execute method: ${error.message}`);
  }
});

router.get("/heirs/:pos", async function(req, res){

  try{
    const executor = req.body.from;
    const priority = req.params.pos;
    const contract = contractService.getTestamentContract();

    let result = await contract.methods.getHeirInPos(priority).call({
      from: executor
    });
    
    let response = formatHeirResult(result, priority);
    if(response.has_minor_child) {
      response['priority_before_child_announced'] = result.priorityBeforeChild;
    }
    res.status(200).send(response);
  }catch(error){
    res.status(500).send(`Cannot execute method: ${error.message}`);
    console.log(`Cannot execute method: ${error.message}`);
  }
});

router.delete("/heirs/:address", async function(req, res){
  try{
    const executor = req.body.from;
    const heir = req.params.address;
    const contract = contractService.getTestamentContract();

    await contract.methods.unsuscribeHeir(heir)
      .send({
          from: executor
      });

    res.status(200).send('Ok');

  }catch(error){
    res.status(500).send(`Cannot execute method: ${error.message}`);
  }
});

router.put("/heirs/:address/priority", async function(req, res){
  try{
    const executor = req.body.from;
    const priority = req.body.priority;
    const heir = req.params.address;
    const contract = contractService.getTestamentContract();

    await contract.methods.changeHeirPriority(heir, priority)
      .send({
          from: executor
      });

    res.status(200).send('Ok');

  }catch(error){
    res.status(500).send(`Cannot execute method: ${error.message}`);
  }
});


router.put("/heirs/:address/percentage", async function(req, res){
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
    res.status(500).send(`Cannot execute method: ${error.message}`);
  }
});


router.put("/heirs/:address/minor", async function(req, res){
  try{
    const executor = req.body.from;
    const heir = req.params.address;
    const contract = contractService.getTestamentContract();

    await contract.methods.announceHeirMinorChild(heir)
      .send({
          from: executor
      });

    res.status(200).send('Ok');

  }catch(error){
    res.status(500).send(`Cannot execute method: ${error.message}`);
  }
});


module.exports = router;

function formatHeirResult(result, pos){
  return {priority: pos+1,heir:result.account, percentage: result.percentage, is_dead: result.isDead, 
    has_minor_child: result.hasMinorChild}
}