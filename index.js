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
const lawsRoute = require('./routes/laws_contract_route');
const timeConfigRoute = require('./routes/time_route');
const inheritanceRoute = require('./routes/inheritance_route');
const withdrawalsRoute = require('./routes/withdrawals_route');

app.use('/api/contract', contractRoute);
app.use('/api/contract', managersRoute);
app.use('/api/contract', heirsRoute);
app.use('/api/contract/time', timeConfigRoute);
app.use('/api/contract/inheritance', inheritanceRoute);
app.use('/api/contract/withdrawals', withdrawalsRoute);
app.use('/api/laws', lawsRoute);

app.listen(port, () => console.log('Listening on port 3000'));

