const express = require('express');
const router = express.Router();
const contractService = require('../services/contract.service');

router.post("/month_length", async function (req, res) {
  try {
    await setMonthLength(req.body.from, req.body.length);
    res.status(200).send(`OK - Set month length to ${req.body.length}`);
  } catch (error) {
    res.status(500).send(`Cannot execute method: ${error.message}`);
  }
});

router.get("/month_length", async function (req, res) {
  try {
    const contract = contractService.getTestamentContract();
    let result = await contract.methods.monthInSeconds().call();
    res.status(200).send(`Month length in seconds: ${result}`);
  } catch (error) {
    res.status(500).send(`Cannot execute method: ${error.message}`);
  }
});

router.post("/day_length", async function (req, res) {
  try {
    await setDayLength(req.body.from, req.body.length);
    res.status(200).send(`OK - Set day length to ${req.body.length}`);
  } catch (error) {
    res.status(500).send(`Cannot execute method: ${error.message}`);
  }
});

router.get("/day_length", async function (req, res) {
  try {
    const contract = contractService.getTestamentContract();
    let result = await contract.methods.dayInSeconds().call();
    res.status(200).send(`Day length in seconds: ${result}`);
  } catch (error) {
    res.status(500).send(`Cannot execute method: ${error.message}`);
  }
});

module.exports = router;

async function setMonthLength(executor, length){
  const contract = contractService.getTestamentContract();
  switch (length) {
    case "second":
      await contract.methods.setMonthLengthSeconds(1).send({
        from: executor
      });
      break;
    case "minute":
      await contract.methods.setMonthLengthSeconds(60).send({
        from: executor
      });      
      break;
    default:
      throw new Error('invalid month length mode');  
  }
}

async function setDayLength(executor, length){
  const contract = contractService.getTestamentContract();
  switch (length) {
    case "second":
      await contract.methods.setDayLengthSeconds(1).send({
        from: executor
      });
      break;
    case "minute":
      await contract.methods.setDayLengthSeconds(60).send({
        from: executor
      });      
      break;
    default:
      throw new Error('invalid day length mode');  
  }
}