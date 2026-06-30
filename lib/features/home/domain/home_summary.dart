class HomeSummary {
  const HomeSummary({
    required this.customerName,
    required this.accountNumber,
    required this.accountType,
    required this.currency,
    required this.balance,
    required this.maskedCard,
    required this.cardType,
  });

  final String customerName;
  final String accountNumber;
  final String accountType;
  final String currency;
  final double balance;
  final String maskedCard;
  final String cardType;

  factory HomeSummary.fromJson(Map<String, dynamic> json) {
    return HomeSummary(
      customerName: json['customerName']?.toString() ?? 'Cliente',
      accountNumber: json['accountNumber']?.toString() ?? '',
      accountType: json['accountType']?.toString() ?? 'SAVINGS',
      currency: json['currency']?.toString() ?? 'PEN',
      balance: double.tryParse(json['balance']?.toString() ?? '') ?? 0,
      maskedCard: json['maskedCard']?.toString() ?? '******',
      cardType: json['cardType']?.toString() ?? 'Tarjeta',
    );
  }

  String get firstName {
    final cleanName = customerName.trim();
    if (cleanName.isEmpty) return 'Cliente';
    return cleanName.split(RegExp(r'\s+')).first;
  }

  String get moneySymbol {
    return currency.toUpperCase() == 'USD' ? r'$' : 'S/';
  }

  String get formattedBalance {
    return '$moneySymbol ${_formatAmount(balance)}';
  }

  String get accountTail {
    if (accountNumber.length <= 4) return accountNumber;
    return accountNumber.substring(accountNumber.length - 4);
  }

  String get accountLabel {
    return switch (accountType.toUpperCase()) {
      'CHECKING' => 'Cuenta corriente',
      'CREDIT' => 'Credito',
      _ => 'Cuenta ahorro',
    };
  }

  static String _formatAmount(double value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts.first;
    final decimals = parts.length > 1 ? parts[1] : '00';
    final buffer = StringBuffer();

    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(whole[i]);
    }

    return '${buffer.toString()}.$decimals';
  }
}
