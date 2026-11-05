class Batch {
  final String id;
  final String productId;
  double quantity;
  double purchasePrice;
  double salePrice;
  final DateTime expiryDate;
  final double contains;
  final String packUnit;
  final DateTime createdAt;
  final DateTime updatedAt;

  Batch({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.purchasePrice,
    required this.salePrice,
    required this.expiryDate,
    this.contains = 1.0,
    this.packUnit = 'حبة',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'quantity': quantity,
      'purchasePrice': purchasePrice,
      'salePrice': salePrice,
      'expiryDate': expiryDate.toIso8601String(),
      'contains': contains,
      'packUnit': packUnit,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Batch.fromMap(Map<String, dynamic> map) {
    return Batch(
      id: map['id'],
      productId: map['productId'],
      quantity: (map['quantity'] as num).toDouble(),
      purchasePrice: (map['purchasePrice'] as num).toDouble(),
      salePrice: (map['salePrice'] as num).toDouble(),
      expiryDate: DateTime.parse(map['expiryDate']),
      contains: (map['contains'] as num?)?.toDouble() ?? 1.0,
      packUnit: map['packUnit'] ?? 'حبة',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}

class Product {
  final String id;
  String name;
  String unitType; // "KILO" | "PIECE" | "LITER"
  String? barcode;
  final DateTime createdAt;
  DateTime updatedAt;
  List<Batch> batches;

  Product({
    required this.id,
    required this.name,
    required this.unitType,
    this.barcode,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Batch>? batches,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        batches = batches ?? [];

  // إحصائيات محسوبة
  double get totalStock => batches.fold(0.0, (sum, b) => sum + b.quantity);
  
  double get totalInvestment =>
      batches.fold(0.0, (sum, b) => sum + (b.quantity * b.purchasePrice));

  double get currentSalePrice {
    if (batches.isEmpty) return 0.0;
    final sorted = List<Batch>.from(batches)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted.first.salePrice;
  }

  double get currentPurchasePrice {
    if (batches.isEmpty) return 0.0;
    final sorted = List<Batch>.from(batches)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted.first.purchasePrice;
  }

  DateTime? get nearestExpiry {
    final active = batches.where((b) => b.quantity > 0).toList();
    if (active.isEmpty) return null;
    active.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return active.first.expiryDate;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'unitType': unitType,
      'barcode': barcode,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, {List<Batch>? batches}) {
    return Product(
      id: map['id'],
      name: map['name'],
      unitType: map['unitType'],
      barcode: map['barcode'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      batches: batches ?? [],
    );
  }
}

class SaleItem {
  final String id;
  final String saleId;
  final String productId;
  final String productName;
  final String unitType;
  final double quantity;
  final double unitPrice;
  final double purchasePrice;
  final double total;

  SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.unitType,
    required this.quantity,
    required this.unitPrice,
    required this.purchasePrice,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'saleId': saleId,
      'productId': productId,
      'productName': productName,
      'unitType': unitType,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'purchasePrice': purchasePrice,
      'total': total,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'],
      saleId: map['saleId'],
      productId: map['productId'],
      productName: map['productName'],
      unitType: map['unitType'],
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unitPrice'] as num).toDouble(),
      purchasePrice: (map['purchasePrice'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
    );
  }
}

class Sale {
  final String id;
  final double total;
  final double amountPaid;
  final double change;
  final DateTime createdAt;
  final List<SaleItem> items;

  Sale({
    required this.id,
    required this.total,
    required this.amountPaid,
    required this.change,
    DateTime? createdAt,
    required this.items,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'total': total,
      'amountPaid': amountPaid,
      'change': change,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map, List<SaleItem> items) {
    return Sale(
      id: map['id'],
      total: (map['total'] as num).toDouble(),
      amountPaid: (map['amountPaid'] as num).toDouble(),
      change: (map['change'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt']),
      items: items,
    );
  }
}

class CustomerPayment {
  final String id;
  final String customerId;
  final String type; // "DEBT" | "PAYMENT"
  final double amount;
  final String? note;
  final DateTime createdAt;

  CustomerPayment({
    required this.id,
    required this.customerId,
    required this.type,
    required this.amount,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'type': type,
      'amount': amount,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CustomerPayment.fromMap(Map<String, dynamic> map) {
    return CustomerPayment(
      id: map['id'],
      customerId: map['customerId'],
      type: map['type'],
      amount: (map['amount'] as num).toDouble(),
      note: map['note'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

class Customer {
  final String id;
  final String code;
  String name;
  String? phone;
  String? note;
  final DateTime createdAt;
  List<CustomerPayment> payments;

  Customer({
    required this.id,
    required this.code,
    required this.name,
    this.phone,
    this.note,
    DateTime? createdAt,
    List<CustomerPayment>? payments,
  })  : createdAt = createdAt ?? DateTime.now(),
        payments = payments ?? [];

  double get balance {
    final debts = payments
        .where((p) => p.type == 'DEBT')
        .fold(0.0, (s, p) => s + p.amount);
    final paid = payments
        .where((p) => p.type == 'PAYMENT')
        .fold(0.0, (s, p) => s + p.amount);
    return debts - paid;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'phone': phone,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map,
      {List<CustomerPayment>? payments}) {
    return Customer(
      id: map['id'],
      code: map['code'],
      name: map['name'],
      phone: map['phone'],
      note: map['note'],
      createdAt: DateTime.parse(map['createdAt']),
      payments: payments ?? [],
    );
  }
}

class SupplierTransaction {
  final String id;
  final String supplierId;
  final String type; // "DEBT" | "PAYMENT"
  final double amount;
  final String? note;
  final DateTime createdAt;

  SupplierTransaction({
    required this.id,
    required this.supplierId,
    required this.type,
    required this.amount,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplierId': supplierId,
      'type': type,
      'amount': amount,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SupplierTransaction.fromMap(Map<String, dynamic> map) {
    return SupplierTransaction(
      id: map['id'],
      supplierId: map['supplierId'],
      type: map['type'],
      amount: (map['amount'] as num).toDouble(),
      note: map['note'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

class Supplier {
  final String id;
  final String code;
  String name;
  String? phone;
  String? note;
  final DateTime createdAt;
  List<SupplierTransaction> transactions;

  Supplier({
    required this.id,
    required this.code,
    required this.name,
    this.phone,
    this.note,
    DateTime? createdAt,
    List<SupplierTransaction>? transactions,
  })  : createdAt = createdAt ?? DateTime.now(),
        transactions = transactions ?? [];

  double get balance {
    final debts = transactions
        .where((t) => t.type == 'DEBT')
        .fold(0.0, (s, t) => s + t.amount);
    final paid = transactions
        .where((t) => t.type == 'PAYMENT')
        .fold(0.0, (s, t) => s + t.amount);
    return debts - paid;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'phone': phone,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map,
      {List<SupplierTransaction>? transactions}) {
    return Supplier(
      id: map['id'],
      code: map['code'] ?? '',
      name: map['name'],
      phone: map['phone'],
      note: map['note'],
      createdAt: DateTime.parse(map['createdAt']),
      transactions: transactions ?? [],
    );
  }
}

class CartItemModel {
  final String productId;
  final String productName;
  final String unitType;
  double quantity;
  double unitPrice;

  CartItemModel({
    required this.productId,
    required this.productName,
    required this.unitType,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;
}
