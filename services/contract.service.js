const path = require('path');
const fs = require('fs');
const solc = require('solc');
const moment = require('moment')
const utils = require('./utils')


const testamentFile = 'Testament.sol';
const contractTestament = 'Testament';

const lawsFile = 'Laws.sol'
const contractLaws = 'Laws'

class ContractService{

  constructor(){}

  compileTestament(){
    compile(testamentFile, contractTestament);
  }

  compileLaws(){
    compile(lawsFile, contractLaws);
  }

  async deployLaws(executor){
    const bytecode = getContractBytecode(contractLaws);
    const abi = getContractAbi(contractLaws);
    const config = getConfig();

    try{
      const result = await new web3.eth.Contract(abi)
        .deploy({
          data: '0x' + bytecode.object,
          arguments: []
        })
        .send({
          gas: '900000',
          from: executor,
        });
        
        config.lawsAddress = result.options.address;
        updateConfig(config);
    }catch(error){
      let _error = error;
      console.log(error.message)
    }

  }

  async deployTestament(heirs, percentages, managers,managerFee ,cancellationFee, isCancFeePercentage, reductionFee,
     isRedFeePercent, maxWithdrawalPercentage, owner, ownerData, inheritanceEthers, organizationAccount){

    const bytecode = getContractBytecode(contractTestament);
    const abi = getContractAbi(contractTestament);
    const config = getConfig();

    try{
      if(config.lawsAddress){
        const result = await new web3.eth.Contract(abi)
        .deploy({
          data: '0x' + bytecode.object,
          arguments: [heirs, percentages, managers, managerFee, cancellationFee, isCancFeePercentage,
          reductionFee, isRedFeePercent, maxWithdrawalPercentage, config.lawsAddress, organizationAccount]
        })
        .send({
          gas: '6000000',
          from: owner,
          value: web3.utils.toWei(`${inheritanceEthers}`, 'ether')
        });

        config.testamentAddress = result.options.address;
        updateConfig(config);
        
        //After deploy, set owner's data.
        let dateUnix = utils.dateStringToUnix(ownerData.birthDate);
        let contract = await this.getTestamentContract();
        await contract.methods.addOwnerData(ownerData.fullName, ownerData.id, dateUnix,
          ownerData.homeAddress,ownerData.telephone, ownerData.email).send({
            gas: '900000',
            from: owner
        });
        return {status: 200, message: 'OK'};
      }else{
        return {status: 400, message: 'Laws need to be compiled and deployed first'};
      }

    }catch(error){
      console.log(error.message)
      throw error;
    }
  }

  getTestamentContract(){
    const configPath = path.resolve(process.cwd(), 'config.json');
    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    const abiPath = path.resolve(process.cwd(), 'contracts', `${contractTestament}_abi.json`);
    const abi = JSON.parse(fs.readFileSync(abiPath, 'utf8'));

    return new web3.eth.Contract(abi,config.testamentAddress);
  }

  getLawsContract(){
    const config = getConfig()
    const abi = getContractAbi(contractLaws);

    return new web3.eth.Contract(abi,config.lawsAddress);
  }

}

module.exports = new ContractService()

function getContractBytecode(contractName){
  const bytecodePath = path.resolve(process.cwd(),'contracts', `${contractName}_bytecode.json`);
  return JSON.parse(fs.readFileSync(bytecodePath, 'utf8')).bytecode;
}

function getContractAbi(contractName){
  const abiPath = path.resolve(process.cwd(), 'contracts', `${contractName}_abi.json`);
  return JSON.parse(fs.readFileSync(abiPath, 'utf8'));
}

function getConfig(){
  const configPath = path.resolve(process.cwd(),'config.json');
  return JSON.parse(fs.readFileSync(configPath, 'utf8'));
}

function updateConfig(configObject){
  const configPath = path.resolve(process.cwd(),'config.json');
  fs.writeFileSync(configPath, JSON.stringify(configObject, null, 2));
}

function getImports(dependency){
  return {contents: fs.readFileSync(path.resolve(process.cwd(), 'contracts', dependency), 'utf8')}
}

function compile(contractFileName, contractName){
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

  const compiledContract = JSON.parse(solc.compile(JSON.stringify(compilerInput), 
                                                  {import: getImports}
                                                  ));

  const contract = compiledContract.contracts[contractName][contractName];
  const abi = contract.abi;
  const abiPath = path.resolve(process.cwd(), 'contracts', `${contractName}_abi.json`);
  fs.writeFileSync(abiPath, JSON.stringify(abi, null, 2));

  const bytecode = contract.evm;
  const bytecodePath = path.resolve(process.cwd(),'contracts', `${contractName}_bytecode.json`);
  fs.writeFileSync(bytecodePath, JSON.stringify(bytecode, null, 2));
}
