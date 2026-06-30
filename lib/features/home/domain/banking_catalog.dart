class TransferBank {
  const TransferBank({
    required this.code,
    required this.name,
    required this.transferFee,
  });

  final String code;
  final String name;
  final double transferFee;

  factory TransferBank.fromJson(Map<String, dynamic> json) {
    return TransferBank(
      code: json['code']?.toString() ?? 'YBANK',
      name: json['name']?.toString() ?? 'YBank',
      transferFee: double.tryParse(json['transferFee']?.toString() ?? '') ?? 0,
    );
  }
}

class ServiceBill {
  const ServiceBill({
    required this.code,
    required this.category,
    required this.provider,
    required this.title,
  });

  final String code;
  final String category;
  final String provider;
  final String title;

  factory ServiceBill.fromJson(Map<String, dynamic> json) {
    return ServiceBill(
      code: json['code']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      provider: json['provider']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
    );
  }
}

class YapeContact {
  const YapeContact({required this.phone, required this.alias});

  final String phone;
  final String alias;

  factory YapeContact.fromJson(Map<String, dynamic> json) {
    return YapeContact(
      phone: json['phone']?.toString() ?? '',
      alias: json['alias']?.toString() ?? '',
    );
  }
}

class MobileOperator {
  const MobileOperator({required this.code, required this.name});

  final String code;
  final String name;

  factory MobileOperator.fromJson(Map<String, dynamic> json) {
    return MobileOperator(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class OperationReceipt {
  const OperationReceipt({
    required this.operationId,
    required this.status,
    required this.amount,
  });

  final String operationId;
  final String status;
  final double amount;

  factory OperationReceipt.fromJson(Map<String, dynamic> json) {
    return OperationReceipt(
      operationId: json['operationId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
    );
  }
}
