import 'dart:math';
import 'package:http/http.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/web3dart.dart';

import 'logging_client.dart';
export 'package:web3dart/credentials.dart';
export 'package:web3dart/web3dart.dart';

enum BlockChainType { Ethereum, Eurus }
enum EnvType { Dev, Staging, Testing }
EnvType envType = EnvType.Staging;

class Web3dart {
  static final Web3dart _instance = Web3dart._internal(
      rpcUrl: envType == EnvType.Staging
          ? "http://13.228.80.104:8545"
          : envType == EnvType.Dev
              ? "http://13.228.169.25:8545"
              : "http://13.228.169.25:8545",
      rinkebyRpcUrl:
          "https://rinkeby.infura.io/v3/fa89761e51884ca48dce5c0b6cfef565",
      httpClient: new LoggingClient(Client()));
  String rpcUrl;
  String rinkebyRpcUrl;
  Client httpClient;
  Web3Client eurusEthClient;
  Web3Client mainNetEthClient;
  EthPrivateKey? credentials;
  int chainId = envType == EnvType.Staging
      ? 2018
      : envType == EnvType.Dev
          ? 2021
          : 2021;
  EthereumAddress? myEthereumAddress;
  String? estimateGasString;
  String? ethBalanceFromEthereum;
  String? erc20TokenBalanceFromEthereum;
  String? ethBalanceFromEurus;
  String? erc20TokenBalanceFromEurus;
  String? lastTxId;
  DeployedContract? erc20ContractFromEthereum;
  DeployedContract? erc20ContractFromEurus;
  List<dynamic> tokenList = [];
  late Map tokenListMap;
  Future<Credentials> Function() get canGetCredentialsHandler =>
      () async => await mainNetEthClient
          .credentialsFromPrivateKey(await canGetPrivateKeyHandler());
  late Future<String> Function() canGetPrivateKeyHandler;
  double ethereumGasPrice = 200000000000;
  double eurusGasPrice = envType == EnvType.Staging
      ? 15000
      : envType == EnvType.Dev
          ? 1500000000000
          : 1500000000000;
  double transactionSpeed = 1;

  /// init method
  Web3dart._internal(
      {required this.rpcUrl,
      required this.rinkebyRpcUrl,
      required this.httpClient})
      : eurusEthClient = new Web3Client(rpcUrl, httpClient),
        mainNetEthClient = new Web3Client(rinkebyRpcUrl, httpClient);

  factory Web3dart() {
    return _instance;
  }

  /// initEthClient
  Future<bool> initEthClient(
      {String? privateKey,
      String? publicAddress,
      Future<String> Function()? canGetPrivateKeyHandler}) async {
    credentials = privateKey != null
        ? await mainNetEthClient.credentialsFromPrivateKey(privateKey)
        : null;
    myEthereumAddress = publicAddress != null
        ? EthereumAddress.fromHex(publicAddress)
        : credentials != null
            ? await credentials!.extractAddress()
            : null;
    print("ethereumAddress:${myEthereumAddress.toString()}");
    // canGetCredentialsHandler = canGetPrivateKeyHandler != null ? () async => await mainNetEthClient.credentialsFromPrivateKey(await canGetPrivateKeyHandler()) : this.canGetCredentialsHandler;
    return true;
  }

  /// setErc20Contract
  DeployedContract setErc20Contract(
      {required String contractAddress,
      required BlockChainType blockChainType}) {
    DeployedContract deployedContract;
    if (blockChainType == BlockChainType.Ethereum) {
      deployedContract =
          getEthereumERC20Contract(contractAddress: contractAddress);
      erc20ContractFromEthereum = deployedContract;
    } else {
      deployedContract =
          getEurusERC20Contract(contractAddress: contractAddress);
      erc20ContractFromEurus = deployedContract;
    }
    return deployedContract;
  }

  /// getBalance
  Future<bool> getErc20Balance(
      {required BlockChainType type, required bool isEthOrEun}) async {
    if (type == BlockChainType.Ethereum) {
      if (!isEthOrEun) {
        if (web3dart.erc20ContractFromEthereum != null) {
          web3dart.erc20TokenBalanceFromEthereum =
              await web3dart.getERC20Balance(
                  blockChainType: BlockChainType.Ethereum,
                  deployedContract: web3dart.erc20ContractFromEthereum!);
        } else {
          return false;
        }
      } else {
        web3dart.ethBalanceFromEthereum = await web3dart.getETHBalance(
            blockChainType: BlockChainType.Ethereum);
      }
    }
    if (type == BlockChainType.Eurus) {
      if (!isEthOrEun) {
        if (web3dart.erc20ContractFromEurus != null) {
          web3dart.erc20TokenBalanceFromEurus = await web3dart.getERC20Balance(
              blockChainType: BlockChainType.Eurus,
              deployedContract: web3dart.erc20ContractFromEurus!);
        } else {
          return false;
        }
      } else {
        web3dart.ethBalanceFromEurus =
            await web3dart.getETHBalance(blockChainType: BlockChainType.Eurus);
      }
    }
    return true;
  }

  /// estimateGas
  Future<String?> estimateGas(
      {required BlockChainType blockChainType,
      required BigInt amount,
      required String toAddress}) async {
    estimateGasString = null;
    Web3Client client = getCurrentClient(blockChainType: blockChainType);
    BigInt estimateGas = await client.estimateGas(
        to: EthereumAddress.fromHex(toAddress),
        value: EtherAmount.inWei(amount));
    EtherAmount etherAmount = EtherAmount.inWei(estimateGas);
    estimateGasString = etherAmount.getValueInUnit(EtherUnit.wei).toString();
    print("estimateGas:$estimateGasString");
    return estimateGasString;
  }

  /// getTransactionFromCallContract
  Transaction getTransactionFromCallContract(
      {required DeployedContract deployedContract,
      required BigInt amount,
      required String toAddress,
      required BlockChainType blockChainType}) {
    ContractFunction transferEvent = deployedContract.function('transfer');
    EthereumAddress toETHAddress = EthereumAddress.fromHex(toAddress);
    Transaction transaction = Transaction.callContract(
      gasPrice: getGasPrice(blockChainType: blockChainType),
      maxGas: 100000,
      contract: deployedContract,
      function: transferEvent,
      parameters: [toETHAddress, amount],
    );
    return transaction;
  }

  /// estimateErcTokenGas
  Future<String?> estimateErcTokenGas(
      {required DeployedContract deployedContract,
      required BlockChainType blockChainType,
      required BigInt amount,
      required String toAddress}) async {
    Web3Client client = getCurrentClient(blockChainType: blockChainType);
    Transaction transaction = getTransactionFromCallContract(
        deployedContract: deployedContract,
        amount: amount,
        toAddress: toAddress,
        blockChainType: blockChainType);
    BigInt estimateGas = await client.estimateGas(
        sender: myEthereumAddress,
        to: EthereumAddress.fromHex(toAddress),
        data: transaction.data);
    double fetchChainIdFromNetworkIdFee =
        blockChainType == BlockChainType.Ethereum ? 1.76 : 1.63;
    estimateGas =
        BigInt.from(estimateGas.toDouble() * fetchChainIdFromNetworkIdFee);
    EtherAmount etherAmount = EtherAmount.inWei(estimateGas);
    estimateGasString = etherAmount.getValueInUnit(EtherUnit.wei).toString();
    print("estimateErcTokenGas:$estimateGasString");
    return estimateGasString;
  }

  /// getEurusInternalConfig
  DeployedContract getEurusInternalConfig() {
    final EthereumAddress contractAddr =
        EthereumAddress.fromHex(envType == EnvType.Staging
            ? '0xDc322792e3a5481692a8D582E500F6588962993b'
            : envType == EnvType.Dev
                ? '0x41796b7Fd9F9E2d79270E77fe311e071B3e5D299'
                : '0x41796b7Fd9F9E2d79270E77fe311e071B3e5D299');
    String abiCode =
        '''[{"inputs":[],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"string","name":"","type":"string"}],"name":"Event","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"}],"name":"OwnerAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"}],"name":"OwnerRemoved","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"addOwner","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"addressList","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[],"name":"eurusUserDepositAddress","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[],"name":"getOwnerCount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[],"name":"getOwners","outputs":[{"internalType":"address[]","name":"","type":"address[]"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[{"internalType":"address","name":"addr","type":"address"}],"name":"isOwner","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[],"name":"platformWalletAddress","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[{"internalType":"address","name":"owner","type":"address"}],"name":"removeOwner","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"renounceOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_currencyAddr","type":"address"},{"internalType":"string","name":"asset","type":"string"}],"name":"addCurrencyInfo","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"asset","type":"string"}],"name":"removeCurrencyInfo","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"asset","type":"string"}],"name":"getErc20SmartContractAddrByAssetName","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[{"internalType":"address","name":"_currencyAddr","type":"address"}],"name":"getErc20SmartContractByAddr","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[{"internalType":"address","name":"coldWalletAddr","type":"address"}],"name":"setPlatformWalletAddress","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"userDepositAddr","type":"address"}],"name":"setEurusUserDepositAddress","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"getAssetAddress","outputs":[{"internalType":"string[]","name":"","type":"string[]"},{"internalType":"address[]","name":"","type":"address[]"}],"stateMutability":"view","type":"function","constant":true}]''';
    DeployedContract contract = DeployedContract(
        ContractAbi.fromJson(abiCode, 'EurusInternalConfig'), contractAddr);
    return contract;
  }

  /// getExternalSmartContractConfig
  DeployedContract getExternalSmartContractConfig() {
    final EthereumAddress contractAddr =
        EthereumAddress.fromHex(envType == EnvType.Staging
            ? '0x8f818f0A202058185aF33167725Def297169Dab2'
            : envType == EnvType.Dev
                ? '0xc41A67DAd764B170788613080BDcb0152B6af968'
                : '0xc41A67DAd764B170788613080BDcb0152B6af968');
    String abiCode =
        '''[{"anonymous":false,"inputs":[{"indexed":false,"internalType":"string","name":"","type":"string"}],"name":"Event","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"}],"name":"OwnerAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"}],"name":"OwnerRemoved","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"reader","type":"address"}],"name":"ReaderAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"reader","type":"address"}],"name":"ReaderRemoved","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"writer","type":"address"}],"name":"WriterAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"writer","type":"address"}],"name":"WriterRemoved","type":"event"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"addOwner","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newReader","type":"address"}],"name":"addReader","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newWriter","type":"address"}],"name":"addWriter","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"addressList","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"currencyList","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getOwnerCount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getOwners","outputs":[{"internalType":"address[]","name":"","type":"address[]"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getReaderList","outputs":[{"internalType":"address[]","name":"","type":"address[]"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getWriterList","outputs":[{"internalType":"address[]","name":"","type":"address[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"addr","type":"address"}],"name":"isOwner","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"addr","type":"address"}],"name":"isWriter","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"}],"name":"removeOwner","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"existingReader","type":"address"}],"name":"removerReader","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"existingWriter","type":"address"}],"name":"removerWriter","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"renounceOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_currencyAddr","type":"address"},{"internalType":"string","name":"asset","type":"string"},{"internalType":"uint256","name":"decimal","type":"uint256"},{"internalType":"string","name":"id","type":"string"}],"name":"addCurrencyInfo","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"asset","type":"string"}],"name":"removeCurrencyInfo","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"asset","type":"string"}],"name":"getErc20SmartContractAddrByAssetName","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_currencyAddr","type":"address"}],"name":"getErc20SmartContractByAddr","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getAssetAddress","outputs":[{"internalType":"string[]","name":"","type":"string[]"},{"internalType":"address[]","name":"","type":"address[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"string","name":"asset","type":"string"}],"name":"getAssetDecimal","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"string","name":"asset","type":"string"}],"name":"getAssetListID","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"ethFee","type":"uint256"},{"internalType":"string[]","name":"asset","type":"string[]"},{"internalType":"uint256[]","name":"amount","type":"uint256[]"}],"name":"setETHFee","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"asset","type":"string"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"setAdminFee","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"asset","type":"string"}],"name":"getAdminFee","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"}]''';
    DeployedContract contract = DeployedContract(
        ContractAbi.fromJson(abiCode, 'ExternalSmartContractConfig'),
        contractAddr);
    return contract;
  }

  /// getEthereumERC20Contract
  DeployedContract getEthereumERC20Contract({required String contractAddress}) {
    final EthereumAddress contractAddr =
        EthereumAddress.fromHex(contractAddress);
    String abiCode =
        '''[{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"spender","type":"address"},{"name":"tokens","type":"uint256"}],"name":"approve","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"from","type":"address"},{"name":"to","type":"address"},{"name":"tokens","type":"uint256"}],"name":"transferFrom","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"tokenOwner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[],"name":"acceptOwnership","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[],"name":"drip","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"to","type":"address"},{"name":"tokens","type":"uint256"}],"name":"transfer","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"spender","type":"address"},{"name":"tokens","type":"uint256"},{"name":"data","type":"bytes"}],"name":"approveAndCall","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"newOwner","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"tokenAddress","type":"address"},{"name":"tokens","type":"uint256"}],"name":"transferAnyERC20Token","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"name":"tokenOwner","type":"address"},{"name":"spender","type":"address"}],"name":"allowance","outputs":[{"name":"remaining","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"inputs":[],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"payable":true,"stateMutability":"payable","type":"fallback"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_from","type":"address"},{"indexed":true,"name":"_to","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"tokens","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"tokenOwner","type":"address"},{"indexed":true,"name":"spender","type":"address"},{"indexed":false,"name":"tokens","type":"uint256"}],"name":"Approval","type":"event"}]''';
    DeployedContract contract = DeployedContract(
        ContractAbi.fromJson(abiCode, 'TestingCoin'), contractAddr);
    return contract;
  }

  /// getEurusERC20Contract
  DeployedContract getEurusERC20Contract({required String contractAddress}) {
    final EthereumAddress contractAddr =
        EthereumAddress.fromHex(contractAddress);
    String abiCode = '''[
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": true,
          "internalType": "address",
          "name": "owner",
          "type": "address"
        },
        {
          "indexed": true,
          "internalType": "address",
          "name": "spender",
          "type": "address"
        },
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "value",
          "type": "uint256"
        }
      ],
      "name": "Approval",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": false,
          "internalType": "string",
          "name": "",
          "type": "string"
        }
      ],
      "name": "Event",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": true,
          "internalType": "address",
          "name": "owner",
          "type": "address"
        }
      ],
      "name": "OwnerAdded",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": true,
          "internalType": "address",
          "name": "owner",
          "type": "address"
        }
      ],
      "name": "OwnerRemoved",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": true,
          "internalType": "address",
          "name": "previousOwner",
          "type": "address"
        },
        {
          "indexed": true,
          "internalType": "address",
          "name": "newOwner",
          "type": "address"
        }
      ],
      "name": "OwnershipTransferred",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": true,
          "internalType": "address",
          "name": "reader",
          "type": "address"
        }
      ],
      "name": "ReaderAdded",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": true,
          "internalType": "address",
          "name": "reader",
          "type": "address"
        }
      ],
      "name": "ReaderRemoved",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": true,
          "internalType": "address",
          "name": "from",
          "type": "address"
        },
        {
          "indexed": true,
          "internalType": "address",
          "name": "to",
          "type": "address"
        },
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "value",
          "type": "uint256"
        }
      ],
      "name": "Transfer",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": true,
          "internalType": "address",
          "name": "writer",
          "type": "address"
        }
      ],
      "name": "WriterAdded",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": true,
          "internalType": "address",
          "name": "writer",
          "type": "address"
        }
      ],
      "name": "WriterRemoved",
      "type": "event"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "newOwner",
          "type": "address"
        }
      ],
      "name": "addOwner",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "newReader",
          "type": "address"
        }
      ],
      "name": "addReader",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "newWriter",
          "type": "address"
        }
      ],
      "name": "addWriter",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "owner",
          "type": "address"
        },
        {
          "internalType": "address",
          "name": "spender",
          "type": "address"
        }
      ],
      "name": "allowance",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "spender",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "amount",
          "type": "uint256"
        }
      ],
      "name": "approve",
      "outputs": [
        {
          "internalType": "bool",
          "name": "",
          "type": "bool"
        }
      ],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "account",
          "type": "address"
        }
      ],
      "name": "balanceOf",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "name": "blackListDestAddress",
      "outputs": [
        {
          "internalType": "address",
          "name": "",
          "type": "address"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "",
          "type": "address"
        }
      ],
      "name": "blackListDestAddressMap",
      "outputs": [
        {
          "internalType": "bool",
          "name": "",
          "type": "bool"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "decimals",
      "outputs": [
        {
          "internalType": "uint8",
          "name": "",
          "type": "uint8"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "spender",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "subtractedValue",
          "type": "uint256"
        }
      ],
      "name": "decreaseAllowance",
      "outputs": [
        {
          "internalType": "bool",
          "name": "",
          "type": "bool"
        }
      ],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "getOwnerCount",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "getOwners",
      "outputs": [
        {
          "internalType": "address[]",
          "name": "",
          "type": "address[]"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "getReaderList",
      "outputs": [
        {
          "internalType": "address[]",
          "name": "",
          "type": "address[]"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "getWriterList",
      "outputs": [
        {
          "internalType": "address[]",
          "name": "",
          "type": "address[]"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "spender",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "addedValue",
          "type": "uint256"
        }
      ],
      "name": "increaseAllowance",
      "outputs": [
        {
          "internalType": "bool",
          "name": "",
          "type": "bool"
        }
      ],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "addr",
          "type": "address"
        }
      ],
      "name": "isOwner",
      "outputs": [
        {
          "internalType": "bool",
          "name": "",
          "type": "bool"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "addr",
          "type": "address"
        }
      ],
      "name": "isWriter",
      "outputs": [
        {
          "internalType": "bool",
          "name": "",
          "type": "bool"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "name",
      "outputs": [
        {
          "internalType": "string",
          "name": "",
          "type": "string"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "owner",
          "type": "address"
        }
      ],
      "name": "removeOwner",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "existingReader",
          "type": "address"
        }
      ],
      "name": "removerReader",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "existingWriter",
          "type": "address"
        }
      ],
      "name": "removerWriter",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "renounceOwnership",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "symbol",
      "outputs": [
        {
          "internalType": "string",
          "name": "",
          "type": "string"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "totalSupply",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "recipient",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "amount",
          "type": "uint256"
        }
      ],
      "name": "transfer",
      "outputs": [
        {
          "internalType": "bool",
          "name": "",
          "type": "bool"
        }
      ],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "sender",
          "type": "address"
        },
        {
          "internalType": "address",
          "name": "recipient",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "amount",
          "type": "uint256"
        }
      ],
      "name": "transferFrom",
      "outputs": [
        {
          "internalType": "bool",
          "name": "",
          "type": "bool"
        }
      ],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "string",
          "name": "name_",
          "type": "string"
        },
        {
          "internalType": "string",
          "name": "symbol_",
          "type": "string"
        },
        {
          "internalType": "uint256",
          "name": "totalSupply_",
          "type": "uint256"
        },
        {
          "internalType": "uint8",
          "name": "decimals_",
          "type": "uint8"
        }
      ],
      "name": "init",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "internalSCAddr",
          "type": "address"
        },
        {
          "internalType": "string",
          "name": "name_",
          "type": "string"
        },
        {
          "internalType": "string",
          "name": "symbol_",
          "type": "string"
        },
        {
          "internalType": "uint256",
          "name": "totalSupply_",
          "type": "uint256"
        },
        {
          "internalType": "uint8",
          "name": "decimals_",
          "type": "uint8"
        }
      ],
      "name": "init",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "account",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "amount",
          "type": "uint256"
        }
      ],
      "name": "mint",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "account",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "amount",
          "type": "uint256"
        }
      ],
      "name": "burn",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "dest",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "withdrawAmount",
          "type": "uint256"
        },
        {
          "internalType": "uint256",
          "name": "amountWithFee",
          "type": "uint256"
        }
      ],
      "name": "submitWithdraw",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "addr",
          "type": "address"
        }
      ],
      "name": "setInternalSCConfigAddress",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "getInternalSCConfigAddress",
      "outputs": [
        {
          "internalType": "address",
          "name": "",
          "type": "address"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "addr",
          "type": "address"
        }
      ],
      "name": "addBlackListDestAddress",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "addr",
          "type": "address"
        }
      ],
      "name": "removeBlackListDestAddress",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    }
  ]''';
    DeployedContract contract = DeployedContract(
        ContractAbi.fromJson(abiCode, 'EurusERC20'), contractAddr);
    return contract;
  }

  /// getCurrentClient
  Web3Client getCurrentClient({required BlockChainType blockChainType}) {
    return blockChainType == BlockChainType.Ethereum
        ? mainNetEthClient
        : eurusEthClient;
  }

  /// get getETHBalance
  Future<String?> getETHBalance(
      {required BlockChainType blockChainType}) async {
    if (myEthereumAddress != null) {
      Web3Client client = getCurrentClient(blockChainType: blockChainType);
      EtherAmount balance = await client.getBalance(myEthereumAddress!);
      String ethBalanceFromEurus =
          balance.getValueInUnit(EtherUnit.ether).toStringAsFixed(8);
      print("getETHBalance:$ethBalanceFromEurus");
      return ethBalanceFromEurus;
    } else {
      return null;
    }
  }

  /// get getERC20Balance
  Future<String> getERC20Balance(
      {required DeployedContract deployedContract,
      required BlockChainType blockChainType}) async {
    Web3Client client = getCurrentClient(blockChainType: blockChainType);
    ContractFunction getBalance = deployedContract.function('balanceOf');
    List balance = await client.call(
        contract: deployedContract,
        function: getBalance,
        params: [myEthereumAddress]);
    BigInt intBalance = balance.first;
    BigInt decimalsBalance = await getContractDecimal(
        deployedContract: deployedContract, blockChainType: blockChainType);
    String decimalsString = "1".padRight(decimalsBalance.toInt() + 1, "0");
    double stringBalance = intBalance / BigInt.from(int.parse(decimalsString));
    print("getERC20Balance:${stringBalance.toString()}");
    return stringBalance.toStringAsFixed(8);
  }

  /// get getETHBalance
  Future<List<dynamic>> getERC20TokenList(
      {required BlockChainType blockChainType}) async {
    Web3Client client = getCurrentClient(blockChainType: blockChainType);
    DeployedContract deployedContract = blockChainType == BlockChainType.Eurus
        ? getExternalSmartContractConfig()
        : getEurusInternalConfig();
    ContractFunction getAssetAddress =
        deployedContract.function('getAssetAddress');
    print("0xdE9c12961680811aa7d068EB727ef4017BA94929");
    tokenList = await client.call(
        contract: deployedContract, function: getAssetAddress, params: []);
    print("tokenList:$tokenList");
    tokenListMap = new Map();
    if (tokenList.isNotEmpty && tokenList[0] != null) {
      for (var i = 0; i < tokenList[0].length; i++) {
        String tokenName = tokenList[0][i];
        EthereumAddress tokenAddress = tokenList[1][i];
        tokenListMap[tokenName] = tokenAddress.toString();
      }
    }
    print('tokenListMap$tokenListMap');
    return tokenList;
  }

  /// getContractDecimal
  Future<BigInt> getContractDecimal(
      {required DeployedContract deployedContract,
      required BlockChainType blockChainType}) async {
    Web3Client client = getCurrentClient(blockChainType: blockChainType);
    ContractFunction getDecimals = deployedContract.function('decimals');
    List decimalsNumber = await client
        .call(contract: deployedContract, function: getDecimals, params: []);
    BigInt decimalsBalance = decimalsNumber.first;
    print("decimalsBalance$decimalsBalance");
    return decimalsBalance;
  }

  /// getEurusUserDepositAddress
  Future<String> getEurusUserDepositAddress() async {
    Web3Client client =
        getCurrentClient(blockChainType: BlockChainType.Ethereum);
    DeployedContract deployedContract = getEurusInternalConfig();
    ContractFunction eurusUserDepositAddress =
        deployedContract.function('eurusUserDepositAddress');
    var address = await client.call(
        contract: deployedContract,
        function: eurusUserDepositAddress,
        params: []);
    print('getEurusUserDepositAddress$address');
    EthereumAddress ethereumAddress = address.first;
    return ethereumAddress.toString();
  }

  /// getTokenSymbol
  Future<String> getTokenSymbol(
      {required DeployedContract deployedContract,
      required BlockChainType blockChainType}) async {
    Web3Client client = getCurrentClient(blockChainType: blockChainType);
    ContractFunction getDecimals = deployedContract.function('symbol');
    List name = await client
        .call(contract: deployedContract, function: getDecimals, params: []);
    String tokenName = name.first;
    print("tokenName:$tokenName");
    return tokenName;
  }

  EtherAmount getGasPrice({required BlockChainType blockChainType}) {
    return EtherAmount.inWei(BigInt.from(
        (blockChainType == BlockChainType.Ethereum
                ? ethereumGasPrice
                : eurusGasPrice) *
            transactionSpeed));
  }

  /// sendETH
  Future<String> sendETH(
      {required double enterAmount,
      required String toAddress,
      required BlockChainType type}) async {
    BigInt amount = BigInt.from(1000000000000000000 * enterAmount);
    EthereumAddress toETHAddress = EthereumAddress.fromHex(toAddress);
    String resultString;
    Web3Client client = getCurrentClient(blockChainType: type);
    if (type == BlockChainType.Ethereum) {
      resultString = await client.sendTransaction(
          credentials ?? await canGetCredentialsHandler(),
          Transaction(
            to: toETHAddress,
            gasPrice: getGasPrice(blockChainType: type),
            maxGas: 100000,
            value: EtherAmount.inWei(amount),
          ),
          fetchChainIdFromNetworkId: true);
    } else {
      resultString = await client.sendTransaction(
          credentials ?? await canGetCredentialsHandler(),
          Transaction(
            gasPrice: getGasPrice(blockChainType: type),
            maxGas: 100000,
            to: toETHAddress,
            value: EtherAmount.inWei(amount),
          ),
          fetchChainIdFromNetworkId: true);
    }
    print("sendETHTransaction resultString:$resultString");
    return resultString;
  }

  /// sendERC20
  Future<String> sendERC20(
      {required DeployedContract deployedContract,
      required double enterAmount,
      required String toAddress,
      required BlockChainType blockChainType}) async {
    String transactionResult;
    Web3Client client = getCurrentClient(blockChainType: blockChainType);
    BigInt decimalsBalance = await getContractDecimal(
        deployedContract: deployedContract, blockChainType: blockChainType);
    String decimalsString = "1".padRight(decimalsBalance.toInt() + 1, "0");
    BigInt amount = BigInt.from(double.parse(decimalsString) * enterAmount);
    print("BigIntamount:$amount");
    Transaction transaction = getTransactionFromCallContract(
        deployedContract: deployedContract,
        amount: amount,
        toAddress: toAddress,
        blockChainType: blockChainType);
    transactionResult = await client.sendTransaction(
        credentials ?? await canGetCredentialsHandler(), transaction,
        chainId: chainId, fetchChainIdFromNetworkId: true);
    print("sendERC20 result:$transactionResult");
    return transactionResult;
  }

  /// submitWithdrawERC20
  Future<String> submitWithdrawERC20(
      {required DeployedContract deployedContract,
      required double enterAmount,
      required double enterAmountWithFee,
      required String toAddress}) async {
    String transactionResult;
    Web3Client client = web3dart.eurusEthClient;
    BigInt decimalsBalance = await getContractDecimal(
        deployedContract: deployedContract,
        blockChainType: BlockChainType.Eurus);
    String decimalsString = "1".padRight(decimalsBalance.toInt() + 1, "0");
    BigInt amount = BigInt.from(double.parse(decimalsString) * enterAmount);
    BigInt amountWithFee =
        BigInt.from(double.parse(decimalsString) * enterAmountWithFee);
    print("BigIntamount:$amount");
    ContractFunction transferEvent =
        deployedContract.function('submitWithdraw');
    EthereumAddress toETHAddress = EthereumAddress.fromHex(toAddress);
    Transaction transaction = Transaction.callContract(
      gasPrice: getGasPrice(blockChainType: BlockChainType.Eurus),
      maxGas: 1000000,
      contract: deployedContract,
      function: transferEvent,
      parameters: [toETHAddress, amount, amountWithFee],
    );
    transactionResult = await client.sendTransaction(
        credentials ?? await canGetCredentialsHandler(), transaction,
        fetchChainIdFromNetworkId: true);
    print("sendERC20 result:$transactionResult");
    return transactionResult;
  }

  /// getETHClientDetail
  Future<Web3Client> getETHClientDetail({BlockChainType? type}) async {
    Web3Client? client = type != null
        ? type == BlockChainType.Ethereum
            ? mainNetEthClient
            : eurusEthClient
        : null;

    print("---------------------- getETHClientDetail ----------------------");
    print("getClientVersion:${await client?.getClientVersion()}");
    print("getBlockNumber:${await client?.getBlockNumber()}");
    print("getGasPrice:${await client?.getGasPrice()}");
    print("getEtherProtocolVersion:${await client?.getEtherProtocolVersion()}");
    print("getMiningHashrate:${await client?.getMiningHashrate()}");
    print("getNetworkId:${await client?.getNetworkId()}");
    print("getPeerCount:${await client?.getPeerCount()}");

    return mainNetEthClient;
  }

  /// getAddressDetail
  Future<Web3Client> getAddressDetail({BlockChainType? type}) async {
    Web3Client? client = type != null
        ? type == BlockChainType.Ethereum
            ? mainNetEthClient
            : eurusEthClient
        : null;

    print("---------------------- getAddressDetail ----------------------");
    print("getBalance:${await client?.getBalance(
      EthereumAddress.fromHex('0x44f426bc9ac7a83521EA140Aeb70523C0a85945a'),
    )}");
    print("etTransactionCount:${await client?.getTransactionCount(
      EthereumAddress.fromHex('0x44f426bc9ac7a83521EA140Aeb70523C0a85945a'),
    )}");
    TransactionReceipt? transactionReceipt = await client?.getTransactionReceipt(
        "0xfa0a7ed6a87b655f2302ce2d88d1d051c4eeef2af6e82de9850f3527a8106744");
    print("---------------------- hash data ----------------------");
    print(
        "transactionReceipt.contractAddress:${transactionReceipt?.contractAddress}");
    print("transactionReceipt.gasUsed:${transactionReceipt?.gasUsed}");
    print("transactionReceipt.from:${transactionReceipt?.from}");
    print("transactionReceipt.to:${transactionReceipt?.to}");

    return mainNetEthClient;
  }

  /// initNewWallet
  void initNewWallet() async {
    var rng = new Random.secure();
    EthPrivateKey random = EthPrivateKey.createRandom(rng);

    var address = await random.extractAddress();
    print("extract address: ${address.hex}");

    Wallet wallet = Wallet.createNew(random, 'password', Random(),
        scryptN: pow(2, 8) as int);
    print("wallet json ${wallet.toJson()}");
  }

  ///cen part
  /// transferRequest
  Future<String> transferRequest(
      {String? symbol,
      required String userWalletAddress,
      required DeployedContract deployedContract,
      required double enterAmount,
      required String toAddress,
      required BlockChainType blockChainType}) async {
    String transactionResult;
    Web3Client client = getCurrentClient(blockChainType: blockChainType);
    BigInt decimalsBalance = await getContractDecimal(
        deployedContract: deployedContract, blockChainType: blockChainType);
    String decimalsString = "1".padRight(decimalsBalance.toInt() + 1, "0");
    BigInt amount = BigInt.from(double.parse(decimalsString) * enterAmount);
    print("BigIntamount:$amount");

    DeployedContract userWalletContract =
        getUserWallet(contractAddr: userWalletAddress);
    ContractFunction transferEvent =
        userWalletContract.function('transferRequest');
    EthereumAddress toETHAddress = EthereumAddress.fromHex(toAddress);
    Transaction transaction = Transaction.callContract(
      gasPrice: getGasPrice(blockChainType: blockChainType),
      maxGas: 100000,
      contract: userWalletContract,
      function: transferEvent,
      parameters: [toETHAddress, amount],
    );

    transactionResult = await client.sendTransaction(
        credentials ?? await canGetCredentialsHandler(), transaction,
        chainId: chainId, fetchChainIdFromNetworkId: true);
    print("sendERC20 result:$transactionResult");
    return transactionResult;
  }

  DeployedContract getUserWallet({required String contractAddr}) {
    final EthereumAddress contractAddr =
        EthereumAddress.fromHex('0xDc322792e3a5481692a8D582E500F6588962993b');
    String abiCode =
        '''[{"inputs":[],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"sender","type":"address"},{"indexed":true,"internalType":"uint256","name":"transactionId","type":"uint256"}],"name":"Confirmation","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"sender","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Deposit","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"string","name":"","type":"string"}],"name":"Event","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"transactionId","type":"uint256"}],"name":"Execution","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"transactionId","type":"uint256"}],"name":"ExecutionFailure","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"}],"name":"OwnerAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"}],"name":"OwnerRemoved","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"reader","type":"address"}],"name":"ReaderAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"reader","type":"address"}],"name":"ReaderRemoved","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"sender","type":"address"},{"indexed":true,"internalType":"uint256","name":"transactionId","type":"uint256"}],"name":"Rejection","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"required","type":"uint256"}],"name":"RequirementChange","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"sender","type":"address"},{"indexed":true,"internalType":"uint256","name":"transactionId","type":"uint256"}],"name":"Revocation","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"transactionId","type":"uint256"}],"name":"Submission","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"transactionId","type":"uint256"},{"indexed":true,"internalType":"string","name":"assetName","type":"string"},{"indexed":true,"internalType":"uint256","name":"amount","type":"uint256"},{"indexed":false,"internalType":"address","name":"dest","type":"address"}],"name":"TransferRequestEvent","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"writer","type":"address"}],"name":"WriterAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"writer","type":"address"}],"name":"WriterRemoved","type":"event"},{"inputs":[],"name":"MAX_OWNER_COUNT","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"TranList","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"addOwner","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newReader","type":"address"}],"name":"addReader","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"operatorAddr","type":"address"}],"name":"addWalletOperator","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newWriter","type":"address"}],"name":"addWriter","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_required","type":"uint256"}],"name":"changeRequirement","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"transactionId","type":"uint256"}],"name":"confirmTransaction","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"address","name":"","type":"address"}],"name":"confirmations","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"transactionId","type":"uint256"}],"name":"getConfirmationCount","outputs":[{"internalType":"uint256","name":"count","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"transactionId","type":"uint256"}],"name":"getConfirmations","outputs":[{"internalType":"address[]","name":"_confirmations","type":"address[]"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getOwnerCount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getOwners","outputs":[{"internalType":"address[]","name":"","type":"address[]"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getReaderList","outputs":[{"internalType":"address[]","name":"","type":"address[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bool","name":"pending","type":"bool"},{"internalType":"bool","name":"executed","type":"bool"}],"name":"getTransactionCount","outputs":[{"internalType":"uint256","name":"count","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"from","type":"uint256"},{"internalType":"uint256","name":"to","type":"uint256"},{"internalType":"bool","name":"pending","type":"bool"},{"internalType":"bool","name":"executed","type":"bool"}],"name":"getTransactionIds","outputs":[{"internalType":"uint256[]","name":"_transactionIds","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getWalletOperatorList","outputs":[{"internalType":"address[]","name":"","type":"address[]"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getWalletOwner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getWriterList","outputs":[{"internalType":"address[]","name":"","type":"address[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"transactionId","type":"uint256"}],"name":"isConfirmed","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"addr","type":"address"}],"name":"isOwner","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"transId","type":"uint256"}],"name":"isRejected","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"addr","type":"address"}],"name":"isWriter","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"string","name":"","type":"string"}],"name":"miscellaneousData","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"transId","type":"uint256"}],"name":"rejectTransaction","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"}],"name":"removeOwner","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"operatorAddr","type":"address"}],"name":"removeWalletOperator","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"existingReader","type":"address"}],"name":"removerReader","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"existingWriter","type":"address"}],"name":"removerWriter","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"renounceOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"required","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"transactionId","type":"uint256"}],"name":"revokeConfirmation","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"addr","type":"address"}],"name":"setWalletOwner","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"a","type":"address"}],"name":"toBytes","outputs":[{"internalType":"bytes","name":"","type":"bytes"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"transactionCount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"transactions","outputs":[{"internalType":"uint256","name":"transId","type":"uint256"},{"internalType":"bool","name":"isDirectInvokeData","type":"bool"},{"internalType":"address","name":"destination","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"},{"internalType":"bytes","name":"data","type":"bytes"},{"internalType":"uint256","name":"timestamp","type":"uint256"},{"internalType":"uint256","name":"blockNumber","type":"uint256"},{"internalType":"bool","name":"executed","type":"bool"},{"internalType":"bool","name":"rejected","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"walletOperatorList","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"walletOwner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"stateMutability":"payable","type":"receive"},{"inputs":[{"internalType":"address","name":"addr","type":"address"}],"name":"setInternalSmartContractConfig","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"dest","type":"address"},{"internalType":"string","name":"assetName","type":"string"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transferRequest","outputs":[{"internalType":"uint256","name":"transactionId","type":"uint256"}],"stateMutability":"nonpayable","type":"function"}]''';
    DeployedContract contract = DeployedContract(
        ContractAbi.fromJson(abiCode, 'UserWallet'), contractAddr);
    return contract;
  }
}

/// you can use web3dart
Web3dart web3dart = Web3dart();
