import 'dart:async';

import 'package:flutter/services.dart';

class Transaction {
  static const MethodChannel _channel = const MethodChannel('transaction');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
