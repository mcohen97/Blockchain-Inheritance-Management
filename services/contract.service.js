const path = require('path');
const fs = require('fs');
const solc = require('solc');


const contractFileName = 'Testament.sol';
const contractName = 'Testament';


const methods = {

  compile(){
    const contractPath = path.resolve(process.cwd(), 'contracts', contractFileName);
    const sourceContent = {};
    sourceContent[contractName] = {content: fs.readFileSync(contractPath, 'utf8')}

    const compilerInput = {
      language: "Solidity",
      sources: sourceContent,
      settings: {
        outputSelection:{
          "*": {
            "*": ["abi", "evm.bytecode"]
          }
        }
      }

    }

    const compiledContract = JSON.parse(solc.compile(JSON.stringify(compilerInput)));

    const contract = compiledContract.contracts[contractName][contractName];
    const abi = contract.abi;
    const abiPath = path.resolve(process.cwd(), 'contracts', 'abi.json');
    fs.writeFileSync(abiPath, JSON.stringify(abi, null, 2));

    const bytecode = contract.evm;
    const bytecodePath = path.resolve(process.cwd(),'contracts', 'bytecode.json');
    fs.writeFileSync(bytecodePath, JSON.stringify(bytecode, null, 2));
  },

  async deploy(){
    const bytecodePath = path.resolve(process.cwd(),'contracts', 'bytecode.json');
    const abiPath = path.resolve(process.cwd(), 'contracts', 'abi.json');
    const configPath = path.resolve(process.cwd(),'config.json');

    const bytecode = JSON.parse(fs.readFileSync(bytecodePath, 'utf8')).bytecode;
    const abi = JSON.parse(fs.readFileSync(abiPath, 'utf8'));

    const accounts = await web3.eth.getAccounts();

    try{
      const result = await new web3.eth.Contract(abi)
        .deploy({
          data: '0x' + bytecode.object,
         // arguments: [accounts[1], accounts[2]]
         arguments: []
        })
        .send({
          gas: '3000000',
          from: accounts[0],
          value: web3.utils.toWei('10', 'ether')
        });
        
        const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
        config.contractAddress = result.options.address;
        fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
    }catch(error){
      let _error = error;
    }
  
  },

  getContract(){
    const configPath = path.resolve(process.cwd(), 'config.json');
    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    const abiPath = path.resolve(process.cwd(), 'contracts', 'abi.json');
    const abi = JSON.parse(fs.readFileSync(abiPath, 'utf8'));

    return new web3.eth.Contract(abi,config.contractAddress);
  }

}

module.exports = {...methods}