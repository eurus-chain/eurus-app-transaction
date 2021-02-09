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
  String usdtBalanceFromEthereum;
  String ethBalanceFromEurus;
  String usdtBalanceFromEurus;
  String lastTxId;
  DeployedContract usdtContractFromEthereum;
  DeployedContract usdtContractFromEurus;

  /// init method
  Web3dart._internal();

  factory Web3dart() {
    return _instance;
  }

  /// initEthClient
  initEthClient({String privateKey}) async {
    mainNetEthClient = new Web3Client(
        'https://rinkeby.infura.io/v3/fa89761e51884ca48dce5c0b6cfef565',
        httpClient);
    eurusEthClient = new Web3Client(rpcUrl, Client());
    credentials = await mainNetEthClient.credentialsFromPrivateKey(privateKey);
    myEthereumAddress = await credentials.extractAddress();
    print("ethereumAddress:${myEthereumAddress.toString()}");
    usdtContractFromEthereum = getEurusUSDTContract(contractAddress: '0x022E292b44B5a146F2e8ee36Ff44D3dd863C915c');
    usdtContractFromEurus = getEurusUSDTContract(contractAddress: '0x8641874C146c9F16F320798055Ff113885D96414');
    getBalance();
  }

  Future<bool> getBalance() async {
    web3dart.usdtBalanceFromEurus =  await web3dart.getERC20Balance(blockChainType: BlockChainType.Eurus,
        deployedContract: web3dart.usdtContractFromEurus,
        decimals: 6);
    web3dart.usdtBalanceFromEthereum = await web3dart.getERC20Balance(blockChainType: BlockChainType.Ethereum,
        deployedContract: web3dart.usdtContractFromEthereum,
        decimals: 18);
    web3dart.ethBalanceFromEurus = await web3dart.getETHBalance(blockChainType: BlockChainType.Eurus);
    web3dart.ethBalanceFromEthereum = await web3dart.getETHBalance(blockChainType: BlockChainType.Ethereum);
    return true;
  }

  Future<String> estimateGas({BlockChainType blockChainType, BigInt amount, String toAddress}) async {
    estimateGasString = null;
    Web3Client client = blockChainType == BlockChainType.Ethereum ? web3dart.mainNetEthClient : web3dart.eurusEthClient;
    BigInt estimateGas = await client.estimateGas(to: EthereumAddress.fromHex(toAddress),value: EtherAmount.inWei(amount));
    EtherAmount etherAmount =  EtherAmount.inWei(estimateGas);
    estimateGasString = etherAmount.getValueInUnit(EtherUnit.gwei).toStringAsFixed(8);
    print("estimateGas:$estimateGasString");
    return estimateGasString;
  }

  Transaction getTransactionFromCallContract({DeployedContract deployedContract, BigInt amount, String toAddress}){
    ContractFunction transferEvent = deployedContract.function('transfer');
    EthereumAddress toETHAddress = EthereumAddress.fromHex(toAddress);
    Transaction transaction = Transaction.callContract(
      contract: deployedContract,
      function: transferEvent,
      parameters: [toETHAddress, amount],
    );
    return transaction;
  }

  Future<String> estimateErcTokenGas({DeployedContract deployedContract,BlockChainType blockChainType, BigInt amount, String toAddress}) async {
    Web3Client client = blockChainType == BlockChainType.Ethereum ? web3dart.mainNetEthClient : web3dart.eurusEthClient;
    Transaction transaction = getTransactionFromCallContract(deployedContract: deployedContract,amount: amount,toAddress: toAddress);
    BigInt estimateGas = await client.estimateGas(to: EthereumAddress.fromHex(toAddress), value: EtherAmount.inWei(amount), data: transaction.data);
    EtherAmount etherAmount =  EtherAmount.inWei(estimateGas);
    estimateGasString = etherAmount.getValueInUnit(EtherUnit.gwei).toStringAsFixed(8);
    print("estimateErcTokenGas:$estimateGasString");
    return estimateGasString;
  }

  DeployedContract getEthereumUSDTContract({String contractAddress}){
    final EthereumAddress contractAddr =
    EthereumAddress.fromHex(contractAddress);
    String abiCode =
    '''[{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"spender","type":"address"},{"name":"tokens","type":"uint256"}],"name":"approve","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"from","type":"address"},{"name":"to","type":"address"},{"name":"tokens","type":"uint256"}],"name":"transferFrom","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"tokenOwner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[],"name":"acceptOwnership","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[],"name":"drip","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"to","type":"address"},{"name":"tokens","type":"uint256"}],"name":"transfer","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"spender","type":"address"},{"name":"tokens","type":"uint256"},{"name":"data","type":"bytes"}],"name":"approveAndCall","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"newOwner","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"tokenAddress","type":"address"},{"name":"tokens","type":"uint256"}],"name":"transferAnyERC20Token","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"name":"tokenOwner","type":"address"},{"name":"spender","type":"address"}],"name":"allowance","outputs":[{"name":"remaining","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"inputs":[],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"payable":true,"stateMutability":"payable","type":"fallback"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_from","type":"address"},{"indexed":true,"name":"_to","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"tokens","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"tokenOwner","type":"address"},{"indexed":true,"name":"spender","type":"address"},{"indexed":false,"name":"tokens","type":"uint256"}],"name":"Approval","type":"event"}]''';
    DeployedContract contract = DeployedContract(
        ContractAbi.fromJson(abiCode, 'TestingCoin'), contractAddr);
    return contract;
  }

  DeployedContract getEurusUSDTContract({String contractAddress}){
    final EthereumAddress contractAddr =
    EthereumAddress.fromHex(contractAddress);
    String abiCode =
    '''[{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"spender","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"string","name":"","type":"string"}],"name":"Event","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"}],"name":"OwnerAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"}],"name":"OwnerRemoved","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Transfer","type":"event"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"addOwner","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"subtractedValue","type":"uint256"}],"name":"decreaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"getOwnerCount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[],"name":"getOwners","outputs":[{"internalType":"address[]","name":"","type":"address[]"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"addedValue","type":"uint256"}],"name":"increaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"addr","type":"address"}],"name":"isOwner","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[{"internalType":"address","name":"owner","type":"address"}],"name":"removeOwner","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"renounceOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transfer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transferFrom","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"name_","type":"string"},{"internalType":"string","name":"symbol_","type":"string"},{"internalType":"uint256","name":"totalSupply_","type":"uint256"},{"internalType":"uint8","name":"decimals_","type":"uint8"}],"name":"init","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"internalSCAddr","type":"address"},{"internalType":"string","name":"name_","type":"string"},{"internalType":"string","name":"symbol_","type":"string"},{"internalType":"uint256","name":"totalSupply_","type":"uint256"},{"internalType":"uint8","name":"decimals_","type":"uint8"}],"name":"init","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"mint","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"burn","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"dest","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"submitWithdraw","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"addr","type":"address"}],"name":"setInternalSCConfigAddress","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"getInternalSCConfigAddress","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function","constant":true}]''';
    DeployedContract contract =
    DeployedContract(ContractAbi.fromJson(abiCode, 'EurusERC20'), contractAddr);
    return contract;
  }

  Web3Client getCurrentClient({BlockChainType blockChainType}){
    return blockChainType == BlockChainType.Ethereum ? mainNetEthClient : eurusEthClient ;
  }

  /// get getETHBalance
  Future<String> getETHBalance({BlockChainType blockChainType}) async {
    Web3Client client = getCurrentClient(blockChainType: blockChainType);
    EtherAmount balance = await client.getBalance(myEthereumAddress);
    ethBalanceFromEurus = balance.getValueInUnit(EtherUnit.ether).toStringAsFixed(8);
    print("getETHBalance:$ethBalanceFromEurus");
    return ethBalanceFromEurus;
  }

  /// get getERC20Balance
  Future<String> getERC20Balance({DeployedContract deployedContract, int decimals, BlockChainType blockChainType}) async {
    ContractFunction getBalance = deployedContract.function('balanceOf');
    Web3Client client = getCurrentClient(blockChainType: blockChainType);
    List balance = await client.call(
        contract: deployedContract, function: getBalance, params: [myEthereumAddress]);
    BigInt intBalance = balance.first;
    String decimalsString = "1".padRight(decimals+1,"0");
    double stringBalance = intBalance/BigInt.from(int.parse(decimalsString));
    print("getERC20Balance:${stringBalance.toString()}");
    return stringBalance.toStringAsFixed(8);
  }


  /// sendETH
  Future<String> sendETH(
      {BigInt amount, String toAddress, BlockChainType type}) async {
    EthereumAddress toETHAddress = EthereumAddress.fromHex(toAddress);
    String resultString;
    if (type == BlockChainType.Ethereum) {
      resultString = await mainNetEthClient.sendTransaction(
          credentials,
          Transaction(
            to: toETHAddress,
            // gasPrice: EtherAmount.inWei(BigInt.one),
            // maxGas: 100000,
            value: EtherAmount.inWei(amount),
          ),
          fetchChainIdFromNetworkId: true);
    } else {
      resultString = await eurusEthClient.sendTransaction(
          credentials,
          Transaction(
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
        BigInt amount,
        String toAddress,
        BlockChainType blockChainType}) async {
    String transactionResult;
    Web3Client client = blockChainType == BlockChainType.Ethereum ? web3dart.mainNetEthClient : web3dart.eurusEthClient;
    Transaction transaction = getTransactionFromCallContract(deployedContract: deployedContract,amount: amount,toAddress: toAddress);
    transactionResult = await client.sendTransaction(
        credentials,
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