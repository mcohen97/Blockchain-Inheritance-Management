const express = require('express');
const router = express.Router();
const contractService = require('../services/contract.service');
const utils = require('../services/utils');
const { default: Web3 } = require('web3');

router.post("/compile", function(req, res){
  try{
    contractService.compileTestament();
    res.status(200).send('OK');
  }catch(error){
    res.status(500).send(new Error('Cannot compile contract'));
  }
});

router.post("/deploy", async function(req, res){
  try{
    const body = req.body;
    let ownerInfo = body.owner_personal_info;
    ownerInfo = {fullName: ownerInfo.full_name, id: ownerInfo.id, birthDate: ownerInfo.birth_date, 
      homeAddress: ownerInfo.home_address, telephone: ownerInfo.telephone, email: ownerInfo.email}

    let result = await contractService.deployTestament(body.heirs, body.percentages, body.managers, body.manager_fee, body.cancellation_fee, 
      body.is_cancel_fee_percent, body.reduction_fee, body.is_reduction_fee_percent, body.max_withdrawal_percentage,
      body.from, ownerInfo, body.inheritance_in_ethers, body.org_account);

    res.status(result.status).send(result.message);
  }catch(error){
    res.status(500).send(`Cannot deploy contract: ${error.message}`);
  }
});

router.delete("/", async function(req, res){
  try{
    const executor = req.body.from;
    const contract = contractService.getTestamentContract();

     await contract.methods.destroy()
      .send({
          from: executor
      });

    res.status(200).send('Destroyed');

  }catch(error){
    res.status(500).send(`Cannot execute method: ${error.message}`);
  }
});

router.get("/owner", async function(req, res){
  try{
    const caller = req.body.from;
    const contract = contractService.getTestamentContract();
    let result = await contract.methods.getOwnersInformation().call({
        from: caller
    });
    
    let ownerData = {'account': result[0], 'full_name': result[1], 'id_number': result[2], 
    'birth_date': utils.unixToDateString(result[3]), 'home_address': result[4], 'telephone': result[5], 'email': result[6],
    'issue_date': utils.unixToDateString(result[7])};

    res.status(200).send(ownerData);
  }catch(error){
    res.status(500).send(`Cannot execute method: ${error.message}`);
    console.log(`Cannot execute method: ${error.message}`);
  }
});

router.get("/information", async function(req, res){
  try{
    const caller = req.body.from;
    const contract = contractService.getTestamentContract();
    let managers = await contract.methods.getManagersCount().call({
        from: caller
    });
    let heirs = await contract.methods.getHeirsCount().call({
      from: caller
    });
    res.status(200).send(`Managers: ${managers}, Heirs: ${heirs}`);
  }catch(error){
    res.status(500).send(`Cannot execute method: ${error.message}`);
  }
});

router.post("/heartbeat", async function(req, res){
  try{
    const executor = req.body.from;
    const contract = contractService.getTestamentContract();
    await contract.methods.heartbeat().send({
      from: executor,
      gas: 1000000
  });

  res.status(200).send('OK');

  }catch(error){
    res.status(500).send(`Cannot execute method: ${error.message}`);
  }

});

router.get("/last_signal", async function(req, res){
  try{
    const executor = req.body.from;
    const contract = contractService.getTestamentContract();
    let result = await contract.methods.lastLifeSignal().call({
      from: executor
  });
  res.status(200).send(utils.unixToDateString(result));
  }catch(error){
    res.status(500).send(`Cannot execute method: ${error.message}`);
  }
});

router.post("/inform_owner_decease", async function(req, res){
  try{
    const executor = req.body.from;
    const contract = contractService.getTestamentContract();
    await contract.methods.informOwnerDecease().send({
      from: executor
  });

  res.status(200).send('OK');
  }catch(error){
    res.status(500).send(`Cannot execute method: ${error.message}`);
  }
});

router.post("/inform_heir_decease", async function (req, res) {
  try {
    const executor = req.body.from;
    const heir = req.body.heir;
    const contract = contractService.getTestamentContract();
    let result = await contract.methods.informHeirDecease(heir).send({
      from: executor
    });

    res.status(200).send(result);
  } catch (error) {
    res.status(500).send(`Cannot execute method: ${error.message}`);
  }
});

module.exports = router;

