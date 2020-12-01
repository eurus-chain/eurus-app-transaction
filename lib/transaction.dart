import 'package:apihandler/apiHandler.dart';
import 'package:transaction/model/coinPrice.dart';

class Transaction {
  static final Transaction _instance = Transaction._internal();

  /// init method
  Transaction._internal();

  factory Transaction() {
    return _instance;
  }

  /// getTopErc20CoinPrice
  Future<CoinPriceList> getTopErc20CoinPrice() async {
    var result = await apiHandler.get(
        "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=wrapped-bitcoin%2Cchainlink%2Cuniswap%2Cyearn-finance%2Cokb%2Comisego%2Cmaker%2Cbasic-attention-token%2Cftx-token%2Ccompound-ether&order=market_cap_desc&per_page=100&page=1&sparkline=false");
    // Map<String, dynamic> resultData = jsonDecode(result);
    CoinPriceList coinPrice = CoinPriceList.fromJson(result);
    return coinPrice;
  }
}

/// you can use Transaction
Transaction transaction = Transaction();
