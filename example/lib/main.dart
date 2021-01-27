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
    web3dart.getOwnerAddress();
    web3dart.setUpPrivateKey(
        privateKey:
            'd1bdc683fbeb9fa0b4ceb26adb39eaffb21b16891ea28e4cf1bc3118fdd39295');
  }

  Future<void> _incrementCounter() async {
    // web3dart.getETHClientDetail();
    // web3dart.getAddressDetail();
    web3dart.sendERC20Transaction(contractAddress: '0x7e0480ca9fd50eb7a3855cf53c347a1b4d6a2ff5',amount: BigInt.from(1000000000000000000),toAddress:'0xA3B4dE5E90A18512BD82c1A640AC99b39ef2258A');
    web3dart.sendEurusETHTransaction(
        amount: BigInt.from(100000000000000000),
        toAddress: '0xA3B4dE5E90A18512BD82c1A640AC99b39ef2258A');

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
