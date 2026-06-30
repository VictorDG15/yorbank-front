class AccountSummary {
  const AccountSummary({
    required this.id,
    required this.number,
    required this.currency,
    required this.balance,
  });

  final String id;
  final String number;
  final String currency;
  final double balance;

  factory AccountSummary.fromJson(Map<String, dynamic> json) => AccountSummary(
        id: json['id'].toString(),
        number: json['accountNumber']?.toString() ?? json['number']?.toString() ?? '0000000000',
        currency: json['currency']?.toString() ?? 'PEN',
        balance: double.tryParse(json['balance'].toString()) ?? 0,
      );

  String get accountTail {
    if (number.length <= 4) return number;
    return number.substring(number.length - 4);
  }

  String get moneySymbol {
    return currency.toUpperCase() == 'USD' ? r'$' : 'S/';
  }

  String get formattedBalance => '$moneySymbol ${balance.toStringAsFixed(2)}';
}
