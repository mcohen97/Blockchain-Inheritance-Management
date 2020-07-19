const express = require('express');
const Web3 = require('web3');
const bodyParser = require('body-parser');
const HDWalletProvider = require('truffle-hdwallet-provider');
const dotenv = require('dotenv').config({path: __dirname + '/.env'});

const port = process.env.port || 3000;

const app = express();
app.use(bodyParser.urlencoded({extended: true}));
app.use(bodyParser.json());

// INFURA:
const seedPhrase = process.env['SEED_PHRASE'];
const accessPoint = process.env['ACCESS_POINT'];
const infuraProvider = new HDWalletProvider(seedPhrase, accessPoint, 0,10);

// GANACHE:
const ganacheProvider = new Web3.providers.HttpProvider('HTTP://127.0.0.1:7545');

let provider = process.env['BLOCKCHAIN_PROVIDER'] == 'INFURA' ? infuraProvider : ganacheProvider;

web3 = new Web3(provider);

//routes
const contractRoute = require('./routes/contract_route');
const managersRoute = require('./routes/managers_route');
const heirsRoute = require('./routes/heirs_route');
const lawsRoute = require('./routes/laws_contract_route');
const timeConfigRoute = require('./routes/time_route');
const inheritanceRoute = require('./routes/inheritance_route');
const withdrawalsRoute = require('./routes/withdrawals_route');

app.use('/api/testament', contractRoute);
app.use('/api/testament/manangers', managersRoute);
app.use('/api/testament/heirs', heirsRoute);
app.use('/api/testament/time', timeConfigRoute);
app.use('/api/testament/inheritance', inheritanceRoute);
app.use('/api/testament/withdrawals', withdrawalsRoute);
app.use('/api/laws', lawsRoute);

app.listen(port, () => console.log('Listening on port 3000'));

