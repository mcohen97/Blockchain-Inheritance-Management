const express = require('express');
const router = express.Router();
const contractService = require('../services/contract.service');
const { default: Web3 } = require('web3');

router.post("/compile", function (req, res) {
  try {
    contractService.compileLaws();
    res.status(200).send('OK');
  } catch (error) {
    res.status(500).send(new Error('Cannot compile contract'));
  }
});

router.post("/deploy", function (req, res) {
  try {
    const body = req.body;
    contractService.deployLaws(body.from);
    res.status(200).send('OK');
  } catch (error) {
    res.status(500).send(new Error('Cannot deploy contract'));
  }
});

router.post("/judiciaryEmployees", async function (req, res) {
  try {
    const executor = req.body.from;
    const address = req.body.judiciaryEmployee;
    const contract = contractService.getLawsContract();
    let result = await contract.methods.addJudiciaryEmployee(address)
      .send({
        from: executor
      });
    res.status(200).send('Ok');
  } catch (error) {
    res.status(500).send(`Cannot execute method: ${error.message}`);
  }
});

router.get("", async function (req, res) {
  try {
    const contract = contractService.getLawsContract();
    let response = {
      dollarToWeiConversion: await contract.methods.dollarToWeiConversion().call(),
      withdrawalFeePercent: await contract.methods.withdrawalFeePercent().call(),
      charitableOrganization: await contract.methods.charitableOrganization().call()
    }
    res.status(200).send(response);
  } catch (error) {
    res.status(500).send(`Cannot retrieve laws contract: ${error.message}`);
  }
});

router.put("/dollarToWeiConversion", async function (req, res) {
  try {
    const executor = req.body.from;
    const dollarToWeiConversion = req.body.dollarToWeiConversion;
    const contract = contractService.getLawsContract();
    let result = await contract.methods.changeDollarToWeiConversion(dollarToWeiConversion)
      .send({
        from: executor
      });
    res.status(200).send('Ok');
  } catch (error) {
    res.status(500).send(`Cannot execute method: ${error.message}`);
  }
});

router.put("/withdrawalFeePercent", async function (req, res) {
  try {
    const executor = req.body.from;
    const withdrawalFeePercent = req.body.withdrawalFeePercent;
    const contract = contractService.getLawsContract();
    let result = await contract.methods.changeWithdrawalFeePercent(withdrawalFeePercent)
      .send({
        from: executor
      });
    res.status(200).send('Ok');
  } catch (error) {
    res.status(500).send(`Cannot execute method: ${error.message}`);
  }
});

router.put("/charitableOrganization", async function (req, res) {
  try {
    const executor = req.body.from;
    const charitableOrganization = req.body.charitableOrganization;
    const contract = contractService.getLawsContract();
    let result = await contract.methods.changeCharitableOrganization(charitableOrganization)
      .send({
        from: executor
      });
    res.status(200).send('Ok');
  } catch (error) {
    res.status(500).send(`Cannot execute method: ${error.message}`);
  }
});

module.exports = router;