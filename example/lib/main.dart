import 'package:transaction/model/coinPrice.dart';
import 'package:transaction/transaction.dart';
import 'package:transaction/web3dart.dart';
import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    web3dart.initEthClient(privateKey: 'd1bdc683fbeb9fa0b4ceb26adb39eaffb21b16891ea28e4cf1bc3118fdd39295');
   // web3dart.getOwnerAddress();
  }

  Future<void> _incrementCounter() async {
    // web3dart.getETHClientDetail();
    // web3dart.getAddressDetail();
    print("ethereumAddress:${web3dart.ethereumAddress.toString()}");
    //if usdt Decimals is 6 than 100000 = 1 amount   like BigInt.from(1000000)
    web3dart.sendERC20(contractAddress: '0x8641874C146c9F16F320798055Ff113885D96414',amount: BigInt.from(1000000),toAddress:'0xA3B4dE5E90A18512BD82c1A640AC99b39ef2258A',type: BlockChainType.Eurus);
   // web3dart.sendETH(amount: BigInt.from(100000),toAddress:'0xA3B4dE5E90A18512BD82c1A640AC99b39ef2258A',type: BlockChainType.Eurus);
    BigInt estimateGas = await web3dart.eurusEthClient.estimateGas(to: EthereumAddress.fromHex('0xA3B4dE5E90A18512BD82c1A640AC99b39ef2258A'),value: EtherAmount.inWei(BigInt.from(1000000)));
    EtherAmount etherAmount =  EtherAmount.inWei(estimateGas);
    print("estimateGas:${ etherAmount.getValueInUnit(EtherUnit.szabo).toStringAsFixed(10)}");
    CoinPriceList coinPrice = await transaction.getTopErc20CoinPrice();
    print("result:$coinPrice");
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text(
            '$_counter',
            style: Theme.of(context).textTheme.headline4,
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _incrementCounter,
          tooltip: 'Increment',
          child: Icon(Icons.add),
        ), // This trail
      ),
    );
  }
}
