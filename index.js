const express = require('express');
const Web3 = require('web3');

const port = process.env.port || 3000;

const app = express();

//HTTP://127.0.0.1:7545
const provider = new Web3.providers.HttpProvider('HTTP://127.0.0.1:7545');
web3 = new Web3(provider);
//routes
const contractRoute = require('./routes/contract.route');
app.use('/api/contract', contractRoute);

app.listen(port, () => console.log('Listening on port 3000'));

