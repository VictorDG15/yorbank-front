class AccountMovement {
  const AccountMovement({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.currency,
    required this.direction,
    required this.category,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final double amount;
  final String currency;
  final String direction;
  final String category;
  final DateTime? createdAt;

  factory AccountMovement.fromJson(Map<String, dynamic> json) {
    return AccountMovement(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Movimiento',
      description: json['description']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
      currency: json['currency']?.toString() ?? 'PEN',
      direction: json['direction']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  bool get isCredit {
    if (direction.toUpperCase() == 'CREDIT') return true;
    return amount > 0;
  }

  String get moneySymbol {
    return currency.toUpperCase() == 'USD' ? r'$' : 'S/';
  }

  String get formattedAmount {
    final sign = isCredit ? '+' : '-';
    return '$sign$moneySymbol ${_formatAmount(amount.abs())}';
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
