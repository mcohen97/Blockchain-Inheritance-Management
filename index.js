const express = require('express');
const Web3 = require('web3');
const bodyParser = require('body-parser');
const HDWalletProvider = require('truffle-hdwallet-provider');

const port = process.env.port || 3000;

const app = express();
app.use(bodyParser.urlencoded({extended: true}));
app.use(bodyParser.json());

const seedPhrase = 'wolf cake game reason oyster clutch artefact prevent poverty flat stumble mansion';
const accessPoint = 'https://ropsten.infura.io/v3/8fca5fe5d6f048b7ba0a9cad31a27def';

//HTTP://127.0.0.1:7545
const ganacheProvider = new Web3.providers.HttpProvider('HTTP://127.0.0.1:7545');
const infuraProvider = new HDWalletProvider(seedPhrase, accessPoint, 0,10);

web3 = new Web3(ganacheProvider);

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

