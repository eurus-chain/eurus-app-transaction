class Transaction {
  static final Transaction _instance = Transaction._internal();

  /// init method
  Transaction._internal();

  factory Transaction() {
    return _instance;
  }
}

/// you can use Transaction
Transaction transaction = Transaction();
