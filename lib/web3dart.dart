import 'dart:math';
import 'package:http/http.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/web3dart.dart';
export 'package:web3dart/credentials.dart';
export 'package:web3dart/web3dart.dart';

enum BlockChainType { Ethereum, Eurus }

class Web3dart {
  static final Web3dart _instance = Web3dart._internal();
  Client httpClient = new Client();
  Web3Client eurusEthClient;
  Web3Client mainNetEthClient;
  Credentials credentials;
  String rpcUrl = "http://13.228.80.104:8545";
  int chainId = 18;
  EthereumAddress myEthereumAddress;
  String estimateGasString;
  String ethBalanceFromEthereum;
  String erc20TokenBalanceFromEthereum;
  String ethBalanceFromEurus;
  String erc20TokenBalanceFromEurus;
  String lastTxId;
  DeployedContract erc20ContractFromEthereum;
  DeployedContract erc20ContractFromEurus;
  List<dynamic> tokenList = new List<dynamic>();
  Map tokenListMap;
  Future<Credentials> Function() get canGetCredentialsHandler => () async => await mainNetEthClient.credentialsFromPrivateKey(await canGetPrivateKeyHandler());
  Future<String> Function() canGetPrivateKeyHandler;
  int ethereumGasPrice = 200000000000;
  int eurusGasPrice = 15000;
  /// init method
  Web3dart._internal();

  factory Web3dart() {
    return _instance;
  }

  /// initEthClient
  Future<bool> initEthClient({String privateKey, String publicAddress, Future<String> Function() canGetPrivateKeyHandler}) async {
    mainNetEthClient = new Web3Client(
        'https://rinkeby.infura.io/v3/fa89761e51884ca48dce5c0b6cfef565',
        httpClient);
    eurusEthClient = new Web3Client(rpcUrl, Client());
    credentials = privateKey != null ? await mainNetEthClient.credentialsFromPrivateKey(privateKey) : null;
    myEthereumAddress = publicAddress != null ? EthereumAddress.fromHex(publicAddress) : credentials != null ? await credentials.extractAddress() : null;
    print("ethereumAddress:${myEthereumAddress.toString()}");
    // canGetCredentialsHandler = canGetPrivateKeyHandler != null ? () async => await mainNetEthClient.credentialsFromPrivateKey(await canGetPrivateKeyHandler()) : this.canGetCredentialsHandler;
    return true;
  }

  /// setErc20Contract
  DeployedContract setErc20Contract({String contractAddress,BlockChainType blockChainType}){
    DeployedContract deployedContract;
    if(blockChainType == BlockChainType.Ethereum){
      erc20ContractFromEthereum = getEthereumERC20Contract(contractAddress: contractAddress);
      deployedContract = erc20ContractFromEthereum;
    } else {
      erc20ContractFromEurus = getEurusERC20Contract(contractAddress: contractAddress);
      deployedContract = erc20ContractFromEurus;
    }
    return deployedContract;
  }

  /// getBalance
  Future<bool> getBalance() async {
    web3dart.erc20TokenBalanceFromEthereum = await web3dart.getERC20Balance(blockChainType: BlockChainType.Ethereum,
        deployedContract: web3dart.erc20ContractFromEthereum);
    web3dart.ethBalanceFromEthereum = await web3dart.getETHBalance(blockChainType: BlockChainType.Ethereum);
    web3dart.erc20TokenBalanceFromEurus =  await web3dart.getERC20Balance(blockChainType: BlockChainType.Eurus,
        deployedContract: web3dart.erc20ContractFromEurus);
    web3dart.ethBalanceFromEurus = await web3dart.getETHBalance(blockChainType: BlockChainType.Eurus);
    return true;
  }

  /// estimateGas
  Future<String> estimateGas({BlockChainType blockChainType, BigInt amount, String toAddress}) async {
    estimateGasString = null;
    Web3Client client = blockChainType == BlockChainType.Ethereum ? web3dart.mainNetEthClient : web3dart.eurusEthClient;
    BigInt estimateGas = await client.estimateGas(to: EthereumAddress.fromHex(toAddress),value: EtherAmount.inWei(amount));
    EtherAmount etherAmount =  EtherAmount.inWei(estimateGas);
    estimateGasString = etherAmount.getValueInUnit(EtherUnit.gwei).toStringAsFixed(8);
    print("estimateGas:$estimateGasString");
    return estimateGasString;
  }

  /// getTransactionFromCallContract
  Transaction getTransactionFromCallContract({DeployedContract deployedContract, BigInt amount, String toAddress,BlockChainType blockChainType}){
    ContractFunction transferEvent = deployedContract.function('transfer');
    EthereumAddress toETHAddress = EthereumAddress.fromHex(toAddress);
    Transaction transaction = Transaction.callContract(
      gasPrice: EtherAmount.inWei(BigInt.from(blockChainType == BlockChainType.Ethereum ? ethereumGasPrice : eurusGasPrice)),
      maxGas: 100000,
      contract: deployedContract,
      function: transferEvent,
      parameters: [toETHAddress, amount],
    );
    return transaction;
  }

  /// estimateErcTokenGas
  Future<String> estimateErcTokenGas({DeployedContract deployedContract,BlockChainType blockChainType, BigInt amount, String toAddress}) async {
    Web3Client client = blockChainType == BlockChainType.Ethereum ? web3dart.mainNetEthClient : web3dart.eurusEthClient;
    Transaction transaction = getTransactionFromCallContract(deployedContract: deployedContract,amount: amount,toAddress: toAddress,blockChainType: blockChainType);
    BigInt estimateGas = await client.estimateGas(sender: myEthereumAddress, to: EthereumAddress.fromHex(toAddress), data: transaction.data);
    EtherAmount etherAmount =  EtherAmount.inWei(estimateGas);
    estimateGasString = etherAmount.getValueInUnit(EtherUnit.gwei).toStringAsFixed(8);
    print("estimateErcTokenGas:$estimateGasString");
    return estimateGasString;
  }

  /// getEurusInternalConfig
  DeployedContract getEurusInternalConfig(){
    final EthereumAddress contractAddr =
    EthereumAddress.fromHex('0xDc322792e3a5481692a8D582E500F6588962993b');
    String abiCode =
    '''[{"inputs":[],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"string","name":"","type":"string"}],"name":"Event","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"}],"name":"OwnerAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"}],"name":"OwnerRemoved","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"addOwner","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"addressList","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[],"name":"eurusUserDepositAddress","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[],"name":"getOwnerCount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[],"name":"getOwners","outputs":[{"internalType":"address[]","name":"","type":"address[]"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[{"internalType":"address","name":"addr","type":"address"}],"name":"isOwner","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[],"name":"platformWalletAddress","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[{"internalType":"address","name":"owner","type":"address"}],"name":"removeOwner","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"renounceOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_currencyAddr","type":"address"},{"internalType":"string","name":"asset","type":"string"}],"name":"addCurrencyInfo","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"asset","type":"string"}],"name":"removeCurrencyInfo","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"asset","type":"string"}],"name":"getErc20SmartContractAddrByAssetName","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[{"internalType":"address","name":"_currencyAddr","type":"address"}],"name":"getErc20SmartContractByAddr","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[{"internalType":"address","name":"coldWalletAddr","type":"address"}],"name":"setPlatformWalletAddress","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"userDepositAddr","type":"address"}],"name":"setEurusUserDepositAddress","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"getAssetAddress","outputs":[{"internalType":"string[]","name":"","type":"string[]"},{"internalType":"address[]","name":"","type":"address[]"}],"stateMutability":"view","type":"function","constant":true}]''';
    DeployedContract contract = DeployedContract(
        ContractAbi.fromJson(abiCode, 'EurusInternalConfig'), contractAddr);
    return contract;
  }

  /// getExternalSmartContractConfig
  DeployedContract getExternalSmartContractConfig(){
    final EthereumAddress contractAddr =
    EthereumAddress.fromHex('0x5E8Df39b190f98F18f4DDe2f3406B0Cd1C833DC0');
    String abiCode =
    '''[{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"addressList","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"currencyList","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"renounceOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_currencyAddr","type":"address"},{"internalType":"string","name":"asset","type":"string"}],"name":"addCurrencyInfo","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"asset","type":"string"}],"name":"removeCurrencyInfo","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"asset","type":"string"}],"name":"getErc20SmartContractAddrByAssetName","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_currencyAddr","type":"address"}],"name":"getErc20SmartContractByAddr","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getAssetAddress","outputs":[{"internalType":"string[]","name":"","type":"string[]"},{"internalType":"address[]","name":"","type":"address[]"}],"stateMutability":"view","type":"function"}]''';
    DeployedContract contract = DeployedContract(
        ContractAbi.fromJson(abiCode, 'ExternalSmartContractConfig'), contractAddr);
    return contract;
  }

  /// getEthereumERC20Contract
  DeployedContract getEthereumERC20Contract({String contractAddress}){
    final EthereumAddress contractAddr =
    EthereumAddress.fromHex(contractAddress);
    String abiCode =
    '''[{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"spender","type":"address"},{"name":"tokens","type":"uint256"}],"name":"approve","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"from","type":"address"},{"name":"to","type":"address"},{"name":"tokens","type":"uint256"}],"name":"transferFrom","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"tokenOwner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[],"name":"acceptOwnership","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[],"name":"drip","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"to","type":"address"},{"name":"tokens","type":"uint256"}],"name":"transfer","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"spender","type":"address"},{"name":"tokens","type":"uint256"},{"name":"data","type":"bytes"}],"name":"approveAndCall","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"newOwner","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"tokenAddress","type":"address"},{"name":"tokens","type":"uint256"}],"name":"transferAnyERC20Token","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"name":"tokenOwner","type":"address"},{"name":"spender","type":"address"}],"name":"allowance","outputs":[{"name":"remaining","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"inputs":[],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"payable":true,"stateMutability":"payable","type":"fallback"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_from","type":"address"},{"indexed":true,"name":"_to","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"tokens","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"tokenOwner","type":"address"},{"indexed":true,"name":"spender","type":"address"},{"indexed":false,"name":"tokens","type":"uint256"}],"name":"Approval","type":"event"}]''';
    DeployedContract contract = DeployedContract(
        ContractAbi.fromJson(abiCode, 'TestingCoin'), contractAddr);
    return contract;
  }

  /// getEurusERC20Contract
  DeployedContract getEurusERC20Contract({String contractAddress}){
    final EthereumAddress contractAddr =
    EthereumAddress.fromHex(contractAddress);
    String abiCode =
    '''[{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"spender","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"string","name":"","type":"string"}],"name":"Event","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"}],"name":"OwnerAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"}],"name":"OwnerRemoved","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Transfer","type":"event"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"addOwner","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"subtractedValue","type":"uint256"}],"name":"decreaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"getOwnerCount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[],"name":"getOwners","outputs":[{"internalType":"address[]","name":"","type":"address[]"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"addedValue","type":"uint256"}],"name":"increaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"addr","type":"address"}],"name":"isOwner","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[{"internalType":"address","name":"owner","type":"address"}],"name":"removeOwner","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"renounceOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transfer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transferFrom","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"name_","type":"string"},{"internalType":"string","name":"symbol_","type":"string"},{"internalType":"uint256","name":"totalSupply_","type":"uint256"},{"internalType":"uint8","name":"decimals_","type":"uint8"}],"name":"init","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"internalSCAddr","type":"address"},{"internalType":"string","name":"name_","type":"string"},{"internalType":"string","name":"symbol_","type":"string"},{"internalType":"uint256","name":"totalSupply_","type":"uint256"},{"internalType":"uint8","name":"decimals_","type":"uint8"}],"name":"init","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"mint","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"burn","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"dest","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"submitWithdraw","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"addr","type":"address"}],"name":"setInternalSCConfigAddress","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"getInternalSCConfigAddress","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function","constant":true}]''';
    DeployedContract contract =
    DeployedContract(ContractAbi.fromJson(abiCode, 'EurusERC20'), contractAddr);
    return contract;
  }

  /// getCurrentClient
  Web3Client getCurrentClient({BlockChainType blockChainType}){
    return blockChainType == BlockChainType.Ethereum ? mainNetEthClient : eurusEthClient ;
  }

  /// get getETHBalance
  Future<String> getETHBalance({BlockChainType blockChainType}) async {
    Web3Client client = getCurrentClient(blockChainType: blockChainType);
    EtherAmount balance = await client.getBalance(myEthereumAddress);
    String ethBalanceFromEurus = balance.getValueInUnit(EtherUnit.ether).toStringAsFixed(8);
    print("getETHBalance:$ethBalanceFromEurus");
    return ethBalanceFromEurus;
  }

  /// get getERC20Balance
  Future<String> getERC20Balance({DeployedContract deployedContract, BlockChainType blockChainType}) async {
    Web3Client client = getCurrentClient(blockChainType: blockChainType);
    ContractFunction getBalance = deployedContract.function('balanceOf');
    List balance = await client.call(
        contract: deployedContract, function: getBalance, params: [myEthereumAddress]);
    BigInt intBalance = balance.first;
    BigInt decimalsBalance = await getContractDecimal(deployedContract: deployedContract,blockChainType: blockChainType);
    String decimalsString = "1".padRight(decimalsBalance.toInt()+1,"0");
    double stringBalance = intBalance/BigInt.from(int.parse(decimalsString));
    print("getERC20Balance:${stringBalance.toString()}");
    return stringBalance.toStringAsFixed(8);
  }

  /// get getETHBalance
  Future<List<dynamic>> getERC20TokenList({BlockChainType blockChainType}) async {
    Web3Client client = getCurrentClient(blockChainType: blockChainType);
    DeployedContract deployedContract =  blockChainType == BlockChainType.Eurus? getExternalSmartContractConfig() : getEurusInternalConfig();
    ContractFunction getAssetAddress = deployedContract.function('getAssetAddress');
    tokenList = await client.call(
        contract: deployedContract, function: getAssetAddress, params: []);
    print("tokenList:$tokenList");
    tokenListMap = new Map();
    if (tokenList != null && tokenList[0] != null) {
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
  Future<BigInt> getContractDecimal({DeployedContract deployedContract, BlockChainType blockChainType}) async {
    Web3Client client = getCurrentClient(blockChainType: blockChainType);
    ContractFunction getDecimals = deployedContract.function('decimals');
    List decimalsNumber = await client.call(
        contract: deployedContract, function: getDecimals, params: []);
    BigInt decimalsBalance = decimalsNumber.first;
    print("decimalsBalance$decimalsBalance");
    return decimalsBalance;
  }

  /// getEurusUserDepositAddress
  Future<String> getEurusUserDepositAddress() async {
    Web3Client client = getCurrentClient(blockChainType: BlockChainType.Ethereum);
    DeployedContract deployedContract =  getEurusInternalConfig();
    ContractFunction eurusUserDepositAddress = deployedContract.function('eurusUserDepositAddress');
    var address = await client.call(
        contract: deployedContract, function: eurusUserDepositAddress, params: []);
    print('getEurusUserDepositAddress$address');
    EthereumAddress ethereumAddress = address.first;
    return ethereumAddress.toString();
  }

  /// getTokenSymbol
  Future<String> getTokenSymbol({DeployedContract deployedContract, BlockChainType blockChainType}) async {
    Web3Client client = getCurrentClient(blockChainType: blockChainType);
    ContractFunction getDecimals = deployedContract.function('symbol');
    List name = await client.call(
        contract: deployedContract, function: getDecimals, params: []);
    String tokenName = name.first;
    print("tokenName:$tokenName");
    return tokenName;
  }

  /// sendETH
  Future<String> sendETH(
      {double enterAmount, String toAddress, BlockChainType type}) async {
    BigInt amount = BigInt.from(1000000000000000000 * enterAmount);
    EthereumAddress toETHAddress = EthereumAddress.fromHex(toAddress);
    String resultString;
    if (type == BlockChainType.Ethereum) {
      resultString = await mainNetEthClient.sendTransaction(
          credentials??await canGetCredentialsHandler(),
          Transaction(
            to: toETHAddress,
            gasPrice: EtherAmount.inWei(BigInt.from(ethereumGasPrice)),
            maxGas: 100000,
            value: EtherAmount.inWei(amount),
          ),
          fetchChainIdFromNetworkId: true);
    } else {
      resultString = await eurusEthClient.sendTransaction(
          credentials??await canGetCredentialsHandler(),
          Transaction(
            gasPrice: EtherAmount.inWei(BigInt.from(eurusGasPrice)),
            maxGas: 100000,
            to: toETHAddress,
            value: EtherAmount.inWei(amount),
          ),
          chainId: chainId,
          fetchChainIdFromNetworkId: true);
    }
    print("sendETHTransaction resultString:$resultString");
    return resultString;
  }

  /// sendERC20
  Future<String> sendERC20(
      {DeployedContract deployedContract,
        double enterAmount,
        String toAddress,
        BlockChainType blockChainType}) async {
    String transactionResult;
    Web3Client client = blockChainType == BlockChainType.Ethereum ? web3dart.mainNetEthClient : web3dart.eurusEthClient;
    BigInt decimalsBalance = await getContractDecimal(deployedContract: deployedContract,blockChainType: blockChainType);
    String decimalsString = "1".padRight(decimalsBalance.toInt()+1,"0");
    BigInt amount = BigInt.from(double.parse(decimalsString) * enterAmount);
    print("BigIntamount:$amount");
    Transaction transaction = getTransactionFromCallContract(deployedContract: deployedContract,amount: amount,toAddress: toAddress,blockChainType: blockChainType);
    transactionResult = await client.sendTransaction(
        credentials??await canGetCredentialsHandler(),
        transaction,
        fetchChainIdFromNetworkId: true);
    print("sendERC20 result:$transactionResult");
    return transactionResult;
  }

  /// submitWithdrawERC20
  Future<String> submitWithdrawERC20(
      {DeployedContract deployedContract,
        double enterAmount,
        String toAddress}) async {
    String transactionResult;
    Web3Client client = web3dart.eurusEthClient;
    BigInt decimalsBalance = await getContractDecimal(deployedContract: deployedContract,blockChainType: BlockChainType.Eurus);
    String decimalsString = "1".padRight(decimalsBalance.toInt()+1,"0");
    BigInt amount = BigInt.from(double.parse(decimalsString) * enterAmount);
    print("BigIntamount:$amount");
    ContractFunction transferEvent = deployedContract.function('submitWithdraw');
    EthereumAddress toETHAddress = EthereumAddress.fromHex(toAddress);
    Transaction transaction = Transaction.callContract(
      gasPrice: EtherAmount.inWei(BigInt.from(ethereumGasPrice)),
      maxGas: 100000,
      contract: deployedContract,
      function: transferEvent,
      parameters: [toETHAddress, amount],
    );
    transactionResult = await client.sendTransaction(
        credentials??await canGetCredentialsHandler(),
        transaction,
        fetchChainIdFromNetworkId: true);
    print("sendERC20 result:$transactionResult");
    return transactionResult;
  }

  /// getETHClientDetail
  Future<Web3Client> getETHClientDetail({BlockChainType type}) async {
    Web3Client client =
    type == BlockChainType.Ethereum ? myEthereumAddress : eurusEthClient;
    print("---------------------- getETHClientDetail ----------------------");
    print("getClientVersion:${await client.getClientVersion()}");
    print("getBlockNumber:${await client.getBlockNumber()}");
    print("getGasPrice:${await client.getGasPrice()}");
    print("getEtherProtocolVersion:${await client.getEtherProtocolVersion()}");
    print("getMiningHashrate:${await client.getMiningHashrate()}");
    print("getNetworkId:${await client.getNetworkId()}");
    print("getPeerCount:${await client.getPeerCount()}");

    return mainNetEthClient;
  }

  /// getAddressDetail
  Future<Web3Client> getAddressDetail({BlockChainType type}) async {
    Web3Client client =
    type == BlockChainType.Ethereum ? myEthereumAddress : eurusEthClient;
    print("---------------------- getAddressDetail ----------------------");
    print("getBalance:${await client.getBalance(
      EthereumAddress.fromHex('0x44f426bc9ac7a83521EA140Aeb70523C0a85945a'),
    )}");
    print("etTransactionCount:${await client.getTransactionCount(
      EthereumAddress.fromHex('0x44f426bc9ac7a83521EA140Aeb70523C0a85945a'),
    )}");
    TransactionReceipt transactionReceipt = await client.getTransactionReceipt(
        "0xfa0a7ed6a87b655f2302ce2d88d1d051c4eeef2af6e82de9850f3527a8106744");
    print("---------------------- hash data ----------------------");
    print(
        "transactionReceipt.contractAddress:${transactionReceipt.contractAddress}");
    print("transactionReceipt.gasUsed:${transactionReceipt.gasUsed}");
    print("transactionReceipt.from:${transactionReceipt.from}");
    print("transactionReceipt.to:${transactionReceipt.to}");
    return mainNetEthClient;
  }

  /// initNewWallet
  void initNewWallet() async {
    var rng = new Random.secure();
    Credentials random = EthPrivateKey.createRandom(rng);

    var address = await random.extractAddress();
    print("extract address: ${address.hex}");

    Wallet wallet =
    Wallet.createNew(random, 'password', Random(), scryptN: pow(2, 8));
    print("wallet json ${wallet.toJson()}");
  }
}

/// you can use web3dart
Web3dart web3dart = Web3dart();