import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transaction/transaction.dart';

void main() {
  const MethodChannel channel = MethodChannel('transaction');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await Transaction.platformVersion, '42');
  });
}
