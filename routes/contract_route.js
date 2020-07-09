const express = require('express');
const router = express.Router();
const contractService = require('../services/contract.service');
const { default: Web3 } = require('web3');

router.post("/compile", function(req, res){
  try{
    contractService.compileTestament();
    res.status(200).send('OK');
  }catch(error){
    res.send(500).send(new Error('Cannot compile contract'));
  }
});

router.post("/deploy", function(req, res){
  try{
    const body = req.body;
    contractService.deployTestament(body.heirs, body.percentages, body.managers, body.manager_fee, body.cancellation_fee, 
      body.is_cancel_fee_percent, body.reduction_fee, body.is_reduction_fee_percent, body.max_withdrawal_percentage);
    res.status(200).send('OK');
  }catch(error){
    //res.send(500).send(new Error('Cannot deploy contract'));
    console.log('Cannot deploy contract');
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
    res.send(500).send(`Cannot execute method: ${error.message}`);
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
    console.log(`Cannot execute method: ${error.message}`);
  }
});

router.get("/inheritance", async function(req, res){
  try{
    const executor = req.body.from;
    const contract = contractService.getTestamentContract();
    let inheritance = await contract.methods.getInheritance().call({
        from: executor
    });

    res.status(200).send(`Inheritance worth: ${inheritance}`);

  }catch(error){
    res.send(500).send(`Cannot execute method: ${error.message}`);
    console.log(`Cannot execute method: ${error.message}`);
  }
});

router.post("/inheritance/increase", async function(req, res){
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
    res.send(500).send(`Cannot execute method: ${error.message}`);
  }
});

router.post("/inheritance/reduce", async function(req, res){
  try{
    const executor = req.body.from;
    const cut = req.body.cut;
    const contract = contractService.getTestamentContract();
    await contract.methods.reduceInheritance(cut).send({
        from: executor,
    });

    res.status(200).send(`Inheritance successfully reduced by: ${cut} percent`);

  }catch(error){
    res.send(500).send(`Cannot execute method: ${error.message}`);
  }
});

router.post("/inheritance/visibility", async function(req, res){
  try{
    const executor = req.body.from;
    const allowed = req.body.value;
    const contract = contractService.getTestamentContract();
    await contract.methods.allowBalanceRead(allowed).send({
        from: executor
    });

    res.status(200).send(`OK`);

  }catch(error){
    res.send(500).send(`Cannot execute method: ${error.message}`);
  }
});

router.get("/inheritance/claim", async function(req, res){
  try{
    const executor = req.body.from;
    const contract = contractService.getTestamentContract();
    result = await contract.methods.claimInheritance().send({
        from: executor
    });

    response = formatClaimEvent(result.events.inheritanceClaim);
    res.status(200).send(response);

  }catch(error){
    res.send(500).send(`Cannot execute method: ${error.message}`);
  }
});

router.post("/withdrawals", async function(req, res){
  try{
    const executor = req.body.from;
    //const ammount = req.body.ammount;
    const ammount = 50000;
    const reason = req.body.reason;
    const contract = contractService.getTestamentContract();
    await contract.methods.withdraw(ammount, reason).send({
        from: executor,
        gas: 1000000
    });

    res.status(200).send(`OK`);

  }catch(error){
    res.send(500).send(`Cannot execute method: ${error.message}`);
  }
});

router.get("/withdrawals", async function(req, res){
  try{
    const contract = contractService.getTestamentContract();
    let eventMethodName = 'withdrawal(address,uint256,string)';
    let filterEventMethod = web3.utils.sha3(eventMethodName);

    let filters = {
      address: contract._address,
      fromBlock: "0x1",
      toBlock: "latest",
      topics: [filterEventMethod]
    }

    let result = await web3.eth.getPastLogs(filters);
    let decoded = result.map(e => formatWithdrawalEvent(e));

    res.status(200).send(decoded);

  }catch(error){
    res.send(500).send(`Cannot execute method: ${error.message}`);
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
    res.send(500).send(`Cannot execute method: ${error.message}`);
  }

});

router.get("/last_signal", async function(req, res){
  try{
    const executor = req.body.from;
    const contract = contractService.getTestamentContract();
    let result = await contract.methods.lastLifeSignal().call({
      from: executor
  });

  res.status(200).send(result);


  }catch(error){
    res.send(500).send(`Cannot execute method: ${error.message}`);
  }

});

router.post("/inform_decease", async function(req, res){
  try{
    const executor = req.body.from;
    const contract = contractService.getTestamentContract();
    let result = await contract.methods.informOwnerDecease().send({
      from: executor
  });

  res.status(200).send(result);
  }catch(error){
    res.status(500).send(`Cannot execute method: ${error.message}`);
  }

});

function formatClaimEvent(event){
  let values = event.returnValues;
  return {liquidated: values.liquidated, message: values.message}
}

function formatWithdrawalEvent(event){
  let decoded = web3.eth.abi.decodeParameters(['uint256', 'string'], event.data);
  return {ammount: decoded['0'], reason: decoded['1']}
}

module.exports = router;