import 'dart:math';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

class Web3dart {
  static final Web3dart _instance = Web3dart._internal();
  Client httpClient = new Client();
  Web3Client eurusEthClient;
  Web3Client mainNetEthClient;
  Credentials credentials;
  String rpcUrl = "http://13.228.80.104:8545";
  int chainId = 18;

  /// init method
  Web3dart._internal() {
    initEthClient();
  }

  factory Web3dart() {
    return _instance;
  }

  /// initEthClient
  initEthClient() async {
    mainNetEthClient = new Web3Client(
        'https://ropsten.infura.io/v3/fa89761e51884ca48dce5c0b6cfef565',
        httpClient);
    credentials = await mainNetEthClient.credentialsFromPrivateKey(
        "d1bdc683fbeb9fa0b4ceb26adb39eaffb21b16891ea28e4cf1bc3118fdd39295");
    eurusEthClient =  new Web3Client(rpcUrl, Client());
  }

  /// setUpPrivateKey
  Future<Credentials> setUpPrivateKey({String privateKey}) async {
    credentials = await mainNetEthClient.credentialsFromPrivateKey(privateKey);
    return credentials;
  }

  /// getOwnerAddress
  void getOwnerAddress() async {
    EthereumAddress contractAddress =
        EthereumAddress.fromHex('0xfeae27388A65eE984F452f86efFEd42AaBD438FD');
    final client = Web3Client(rpcUrl, Client());
    String contractAbi = '''[
      {
        "inputs": [],
        "payable": false,
        "stateMutability": "nonpayable",
        "type": "constructor"
      },
      {
        "anonymous": false,
        "inputs": [
          {
            "indexed": true,
            "internalType": "address",
            "name": "oldOwner",
            "type": "address"
          },
          {
            "indexed": true,
            "internalType": "address",
            "name": "newOwner",
            "type": "address"
          }
        ],
        "name": "OwnerSet",
        "type": "event"
      },
      {
        "constant": false,
        "inputs": [
          {
            "internalType": "address",
            "name": "newOwner",
            "type": "address"
          }
        ],
        "name": "changeOwner",
        "outputs": [],
        "payable": false,
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "constant": true,
        "inputs": [],
        "name": "getOwner",
        "outputs": [
          {
            "internalType": "address",
            "name": "",
            "type": "address"
          }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
      }
    ]''';

    final contract = DeployedContract(
        ContractAbi.fromJson(contractAbi, 'contract'), contractAddress);

    final setOwnerFunction = contract.function('getOwner');

    client
        .call(
          contract: contract,
          function: setOwnerFunction,
          params: [],
        )
        .then((value) => print("company eth node getOwner: $value"))
        .catchError((e) => print("catchError $e"));
  }

  /// sendETHTransaction
  Future<String> sendETHTransaction(
      {EtherAmount amount, String toAddress}) async {
    EthereumAddress toETHAddress = EthereumAddress.fromHex(toAddress);
    String resultString = await mainNetEthClient.sendTransaction(
        credentials,
        Transaction(
          to: toETHAddress,
          gasPrice: EtherAmount.inWei(BigInt.one),
          maxGas: 100000,
          value: amount,
        ),
        fetchChainIdFromNetworkId: true);

    print("sendTransaction resultString:$resultString");
    return resultString;
  }

  /// sendEurusETHTransaction
  Future<String> sendEurusETHTransaction(
      {BigInt amount, String toAddress}) async {
    EthereumAddress toETHAddress = EthereumAddress.fromHex(toAddress);
    String resultString = await eurusEthClient.sendTransaction(
        credentials,
        Transaction(
          to: toETHAddress,
          value: EtherAmount.inWei(amount),
        ),
        chainId: chainId,
        fetchChainIdFromNetworkId: true);

    print("sendTransaction resultString:$resultString");
    return resultString;
  }

  /// sendERC20Transaction
  Future<String> sendERC20Transaction(
      {String contractAddress, BigInt amount, String toAddress}) async {
    EthereumAddress toETHAddress = EthereumAddress.fromHex(toAddress);
    final EthereumAddress contractAddr =
        EthereumAddress.fromHex(contractAddress);
    String abiCode =
        '''[{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"spender","type":"address"},{"name":"tokens","type":"uint256"}],"name":"approve","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"from","type":"address"},{"name":"to","type":"address"},{"name":"tokens","type":"uint256"}],"name":"transferFrom","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"tokenOwner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[],"name":"acceptOwnership","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[],"name":"drip","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"to","type":"address"},{"name":"tokens","type":"uint256"}],"name":"transfer","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"spender","type":"address"},{"name":"tokens","type":"uint256"},{"name":"data","type":"bytes"}],"name":"approveAndCall","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"newOwner","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"tokenAddress","type":"address"},{"name":"tokens","type":"uint256"}],"name":"transferAnyERC20Token","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"name":"tokenOwner","type":"address"},{"name":"spender","type":"address"}],"name":"allowance","outputs":[{"name":"remaining","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"inputs":[],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"payable":true,"stateMutability":"payable","type":"fallback"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_from","type":"address"},{"indexed":true,"name":"_to","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"tokens","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"tokenOwner","type":"address"},{"indexed":true,"name":"spender","type":"address"},{"indexed":false,"name":"tokens","type":"uint256"}],"name":"Approval","type":"event"}]''';
    final contract = DeployedContract(
        ContractAbi.fromJson(abiCode, 'TestingCoin'), contractAddr);
    final transferEvent = contract.function('transfer');

    String sendTransaction = await mainNetEthClient.sendTransaction(
        credentials,
        Transaction.callContract(
          contract: contract,
          function: transferEvent,
          parameters: [toETHAddress, amount],
        ),
        fetchChainIdFromNetworkId: true);
    print("sendTransaction result:$sendTransaction");

    return sendTransaction;
  }

  /// getETHClientDetail
  Future<Web3Client> getETHClientDetail({Web3Client client}) async {
    print("---------------------- getETHClientDetail ----------------------");
    print("getClientVersion:${await client.getClientVersion()}");
    print("getBlockNumber:${await client.getBlockNumber()}");
    print("getGasPrice:${await client.getGasPrice()}");
    print(
        "getEtherProtocolVersion:${await client.getEtherProtocolVersion()}");
    print("getMiningHashrate:${await client.getMiningHashrate()}");
    print("getNetworkId:${await client.getNetworkId()}");
    print("getPeerCount:${await client.getPeerCount()}");

    return mainNetEthClient;
  }

  /// getAddressDetail
  Future<Web3Client> getAddressDetail({Web3Client client}) async {
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
