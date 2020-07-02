const express = require('express');
const Web3 = require('web3');
const bodyParser = require('body-parser');

const port = process.env.port || 3000;

const app = express();
app.use(bodyParser.urlencoded({extended: true}));
app.use(bodyParser.json());

//HTTP://127.0.0.1:7545
const provider = new Web3.providers.HttpProvider('HTTP://127.0.0.1:7545');
web3 = new Web3(provider);

//routes
const contractRoute = require('./routes/contract_route');
const managersRoute = require('./routes/managers_route');
const heirsRoute = require('./routes/heirs_route');

app.use('/api/contract', contractRoute);
app.use('/api/contract', managersRoute);
app.use('/api/contract', heirsRoute);

app.listen(port, () => console.log('Listening on port 3000'));

