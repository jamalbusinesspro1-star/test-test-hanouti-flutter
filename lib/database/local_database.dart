import 'dart:convert';
import 'package:sqflite/sqflite.dart' hide Batch;
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;
  final _uuid = const Uuid();

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hanouti.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        unitType TEXT NOT NULL,
        barcode TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE batches (
        id TEXT PRIMARY KEY,
        productId TEXT NOT NULL,
        quantity REAL NOT NULL,
        purchasePrice REAL NOT NULL,
        salePrice REAL NOT NULL,
        expiryDate TEXT NOT NULL,
        contains REAL NOT NULL,
        packUnit TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id TEXT PRIMARY KEY,
        total REAL NOT NULL,
        amountPaid REAL NOT NULL,
        change REAL NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items (
        id TEXT PRIMARY KEY,
        saleId TEXT NOT NULL,
        productId TEXT NOT NULL,
        productName TEXT NOT NULL,
        unitType TEXT NOT NULL,
        quantity REAL NOT NULL,
        unitPrice REAL NOT NULL,
        purchasePrice REAL NOT NULL,
        total REAL NOT NULL,
        FOREIGN KEY (saleId) REFERENCES sales (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        code TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        note TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE customer_payments (
        id TEXT PRIMARY KEY,
        customerId TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        note TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE suppliers (
        id TEXT PRIMARY KEY,
        code TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        note TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE supplier_transactions (
        id TEXT PRIMARY KEY,
        supplierId TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        note TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (supplierId) REFERENCES suppliers (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // الإعدادات المبدئية
    await db.insert('settings', {
      'key': 'shopName',
      'value': 'حانوتي',
    });
    await db.insert('settings', {
      'key': 'ownerName',
      'value': 'مول الحانوت',
    });
    await db.insert('settings', {
      'key': 'ownerPhone',
      'value': '',
    });
  }

  // ===== المنتجات والدفعات =====

  Future<List<Product>> getProducts() async {
    final db = await instance.database;
    final productsMap = await db.query('products', orderBy: 'name ASC');
    final batchesMap = await db.query('batches');

    final batchesByProduct = <String, List<Batch>>{};
    for (var bMap in batchesMap) {
      final b = Batch.fromMap(bMap);
      batchesByProduct.putIfAbsent(b.productId, () => []).add(b);
    }

    return productsMap.map((pMap) {
      final pId = pMap['id'] as String;
      return Product.fromMap(pMap, batches: batchesByProduct[pId] ?? []);
    }).toList();
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await instance.database;
    final clean = barcode.trim();
    final res = await db.query('products', where: 'barcode = ?', whereArgs: [clean]);
    if (res.isEmpty) return null;
    final pMap = res.first;
    final pId = pMap['id'] as String;
    final batchesMap = await db.query('batches', where: 'productId = ?', whereArgs: [pId]);
    return Product.fromMap(pMap, batches: batchesMap.map((b) => Batch.fromMap(b)).toList());
  }

  Future<void> createProduct({
    required String name,
    required String unitType,
    required double quantity,
    required double purchasePrice,
    required double salePrice,
    required DateTime expiryDate,
    String? barcode,
    String? supplierId,
    double contains = 1.0,
    String packUnit = 'حبة',
  }) async {
    final db = await instance.database;
    final pId = _uuid.v4();
    final now = DateTime.now();

    final product = Product(
      id: pId,
      name: name.trim(),
      unitType: unitType,
      barcode: barcode?.trim().isEmpty == true ? null : barcode?.trim(),
      createdAt: now,
      updatedAt: now,
    );

    final batch = Batch(
      id: _uuid.v4(),
      productId: pId,
      quantity: quantity,
      purchasePrice: purchasePrice,
      salePrice: salePrice,
      expiryDate: expiryDate,
      contains: contains,
      packUnit: packUnit,
      createdAt: now,
      updatedAt: now,
    );

    await db.transaction((txn) async {
      await txn.insert('products', product.toMap());
      await txn.insert('batches', batch.toMap());

      if (supplierId != null && (purchasePrice * quantity) > 0) {
        await txn.insert('supplier_transactions', {
          'id': _uuid.v4(),
          'supplierId': supplierId,
          'type': 'DEBT',
          'amount': purchasePrice * quantity,
          'note': 'شراء سلعة: ${product.name}',
          'createdAt': now.toIso8601String(),
        });
      }
    });
  }

  Future<void> updateProduct(String id, String name, String? barcode, String unitType) async {
    final db = await instance.database;
    await db.update(
      'products',
      {
        'name': name.trim(),
        'barcode': barcode?.trim().isEmpty == true ? null : barcode?.trim(),
        'unitType': unitType,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteProduct(String id) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('batches', where: 'productId = ?', whereArgs: [id]);
      await txn.delete('products', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> addBatch({
    required String productId,
    required double quantity,
    required double purchasePrice,
    required double salePrice,
    required DateTime expiryDate,
    String? supplierId,
    double contains = 1.0,
    String packUnit = 'حبة',
  }) async {
    final db = await instance.database;
    final now = DateTime.now();
    final batch = Batch(
      id: _uuid.v4(),
      productId: productId,
      quantity: quantity,
      purchasePrice: purchasePrice,
      salePrice: salePrice,
      expiryDate: expiryDate,
      contains: contains,
      packUnit: packUnit,
      createdAt: now,
      updatedAt: now,
    );

    await db.transaction((txn) async {
      await txn.insert('batches', batch.toMap());
      if (supplierId != null && (purchasePrice * quantity) > 0) {
        await txn.insert('supplier_transactions', {
          'id': _uuid.v4(),
          'supplierId': supplierId,
          'type': 'DEBT',
          'amount': purchasePrice * quantity,
          'note': 'تزويد دفعة مخزون',
          'createdAt': now.toIso8601String(),
        });
      }
    });
  }

  Future<void> updateBatch(Batch b) async {
    final db = await instance.database;
    await db.update(
      'batches',
      b.toMap(),
      where: 'id = ?',
      whereArgs: [b.id],
    );
  }

  Future<void> deleteBatch(String batchId) async {
    final db = await instance.database;
    await db.delete('batches', where: 'id = ?', whereArgs: [batchId]);
  }

  // ===== نقطة البيع والمبيعات (FIFO) =====

  Future<List<Sale>> getSales({String? dateStr}) async {
    final db = await instance.database;
    List<Map<String, dynamic>> salesMap;
    if (dateStr != null && dateStr.isNotEmpty) {
      salesMap = await db.query(
        'sales',
        where: "createdAt LIKE ?",
        whereArgs: ['$dateStr%'],
        orderBy: 'createdAt DESC',
      );
    } else {
      salesMap = await db.query('sales', orderBy: 'createdAt DESC');
    }

    final result = <Sale>[];
    for (var sMap in salesMap) {
      final sId = sMap['id'] as String;
      final itemsMap = await db.query('sale_items', where: 'saleId = ?', whereArgs: [sId]);
      final items = itemsMap.map((i) => SaleItem.fromMap(i)).toList();
      result.add(Sale.fromMap(sMap, items));
    }
    return result;
  }

  Future<Sale> createSale({
    required List<CartItemModel> items,
    required double amountPaid,
    String? customerId,
  }) async {
    final db = await instance.database;
    final now = DateTime.now();
    final saleId = _uuid.v4();
    final total = items.fold(0.0, (sum, it) => sum + it.total);
    final isCredit = customerId != null;
    final change = isCredit ? 0.0 : (amountPaid >= total ? amountPaid - total : 0.0);

    final saleItems = <SaleItem>[];

    await db.transaction((txn) async {
      // التحقق من المخزون وتطبيقه بـ FIFO
      for (var it in items) {
        final bMaps = await txn.query(
          'batches',
          where: 'productId = ? AND quantity > 0',
          whereArgs: [it.productId],
          orderBy: 'expiryDate ASC',
        );

        final batches = bMaps.map((b) => Batch.fromMap(b)).toList();
        final availableStock = batches.fold(0.0, (s, b) => s + b.quantity);

        if (availableStock < it.quantity) {
          throw Exception('المخزون غير كافٍ لـ: ${it.productName}');
        }

        double needed = it.quantity;
        for (var b in batches) {
          if (needed <= 0) break;
          double deduct = b.quantity > needed ? needed : b.quantity;
          b.quantity -= deduct;
          needed -= deduct;
          await txn.update(
            'batches',
            {'quantity': b.quantity, 'updatedAt': now.toIso8601String()},
            where: 'id = ?',
            whereArgs: [b.id],
          );
        }

        double purchasePrice = batches.isNotEmpty ? batches.first.purchasePrice : 0.0;

        final sItem = SaleItem(
          id: _uuid.v4(),
          saleId: saleId,
          productId: it.productId,
          productName: it.productName,
          unitType: it.unitType,
          quantity: it.quantity,
          unitPrice: it.unitPrice,
          purchasePrice: purchasePrice,
          total: it.total,
        );
        saleItems.add(sItem);
        await txn.insert('sale_items', sItem.toMap());
      }

      final sale = Sale(
        id: saleId,
        total: total,
        amountPaid: isCredit ? 0.0 : amountPaid,
        change: change,
        createdAt: now,
        items: saleItems,
      );

      await txn.insert('sales', sale.toMap());

      if (isCredit) {
        await txn.insert('customer_payments', {
          'id': _uuid.v4(),
          'customerId': customerId,
          'type': 'DEBT',
          'amount': total,
          'note': 'معاملة بيع #${saleId.substring(0, 6)}',
          'createdAt': now.toIso8601String(),
        });
      }
    });

    return Sale(
      id: saleId,
      total: total,
      amountPaid: isCredit ? 0.0 : amountPaid,
      change: change,
      createdAt: now,
      items: saleItems,
    );
  }

  Future<void> deleteSale(String saleId) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      final itemsMap = await txn.query('sale_items', where: 'saleId = ?', whereArgs: [saleId]);
      // إعادة الكميات للمخزون
      for (var itMap in itemsMap) {
        final pId = itMap['productId'] as String;
        final qty = (itMap['quantity'] as num).toDouble();
        final batches = await txn.query('batches', where: 'productId = ?', whereArgs: [pId], limit: 1);
        if (batches.isNotEmpty) {
          final bId = batches.first['id'] as String;
          final currentQty = (batches.first['quantity'] as num).toDouble();
          await txn.update('batches', {'quantity': currentQty + qty}, where: 'id = ?', whereArgs: [bId]);
        }
      }
      await txn.delete('sale_items', where: 'saleId = ?', whereArgs: [saleId]);
      await txn.delete('sales', where: 'id = ?', whereArgs: [saleId]);
    });
  }

  // ===== الزبناء (الكريدي) =====

  Future<List<Customer>> getCustomers() async {
    final db = await instance.database;
    final customersMap = await db.query('customers', orderBy: 'name ASC');
    final paymentsMap = await db.query('customer_payments', orderBy: 'createdAt DESC');

    final payByCust = <String, List<CustomerPayment>>{};
    for (var pMap in paymentsMap) {
      final p = CustomerPayment.fromMap(pMap);
      payByCust.putIfAbsent(p.customerId, () => []).add(p);
    }

    return customersMap.map((cMap) {
      final cId = cMap['id'] as String;
      return Customer.fromMap(cMap, payments: payByCust[cId] ?? []);
    }).toList();
  }

  Future<void> createCustomer(String name, String? phone, String? note, double initialDebt) async {
    final db = await instance.database;
    final cId = _uuid.v4();
    final now = DateTime.now();
    final code = 'C${(1000 + DateTime.now().millisecond % 9000)}';

    await db.transaction((txn) async {
      await txn.insert('customers', {
        'id': cId,
        'code': code,
        'name': name.trim(),
        'phone': phone?.trim(),
        'note': note?.trim(),
        'createdAt': now.toIso8601String(),
      });

      if (initialDebt > 0) {
        await txn.insert('customer_payments', {
          'id': _uuid.v4(),
          'customerId': cId,
          'type': 'DEBT',
          'amount': initialDebt,
          'note': 'كريدي سابق',
          'createdAt': now.toIso8601String(),
        });
      }
    });
  }

  Future<void> addCustomerPayment(String customerId, String type, double amount, String? note) async {
    final db = await instance.database;
    await db.insert('customer_payments', {
      'id': _uuid.v4(),
      'customerId': customerId,
      'type': type,
      'amount': amount,
      'note': note?.trim(),
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteCustomer(String customerId) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('customer_payments', where: 'customerId = ?', whereArgs: [customerId]);
      await txn.delete('customers', where: 'id = ?', whereArgs: [customerId]);
    });
  }

  // ===== الموردون =====

  Future<List<Supplier>> getSuppliers() async {
    final db = await instance.database;
    final suppliersMap = await db.query('suppliers', orderBy: 'name ASC');
    final txMap = await db.query('supplier_transactions', orderBy: 'createdAt DESC');

    final txBySupp = <String, List<SupplierTransaction>>{};
    for (var tMap in txMap) {
      final t = SupplierTransaction.fromMap(tMap);
      txBySupp.putIfAbsent(t.supplierId, () => []).add(t);
    }

    return suppliersMap.map((sMap) {
      final sId = sMap['id'] as String;
      return Supplier.fromMap(sMap, transactions: txBySupp[sId] ?? []);
    }).toList();
  }

  Future<void> createSupplier(String name, String? phone, String? note, double initialDebt) async {
    final db = await instance.database;
    final sId = _uuid.v4();
    final now = DateTime.now();
    final code = 'S${(1000 + DateTime.now().millisecond % 9000)}';

    await db.transaction((txn) async {
      await txn.insert('suppliers', {
        'id': sId,
        'code': code,
        'name': name.trim(),
        'phone': phone?.trim(),
        'note': note?.trim(),
        'createdAt': now.toIso8601String(),
      });

      if (initialDebt > 0) {
        await txn.insert('supplier_transactions', {
          'id': _uuid.v4(),
          'supplierId': sId,
          'type': 'DEBT',
          'amount': initialDebt,
          'note': 'دين سابق',
          'createdAt': now.toIso8601String(),
        });
      }
    });
  }

  Future<void> addSupplierTransaction(String supplierId, String type, double amount, String? note) async {
    final db = await instance.database;
    await db.insert('supplier_transactions', {
      'id': _uuid.v4(),
      'supplierId': supplierId,
      'type': type,
      'amount': amount,
      'note': note?.trim(),
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteSupplier(String supplierId) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('supplier_transactions', where: 'supplierId = ?', whereArgs: [supplierId]);
      await txn.delete('suppliers', where: 'id = ?', whereArgs: [supplierId]);
    });
  }

  // ===== الإعدادات والنسخ الاحتياطي =====

  Future<Map<String, String>> getSettings() async {
    final db = await instance.database;
    final list = await db.query('settings');
    final map = <String, String>{};
    for (var row in list) {
      map[row['key'] as String] = row['value'] as String;
    }
    return map;
  }

  Future<void> updateSetting(String key, String value) async {
    final db = await instance.database;
    await db.insert('settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String> exportBackupJson() async {
    final products = await getProducts();
    final sales = await getSales();
    final customers = await getCustomers();
    final suppliers = await getSuppliers();

    final data = {
      'appName': 'hanouti_flutter',
      'exportedAt': DateTime.now().toIso8601String(),
      'products': products.map((p) => {
        ...p.toMap(),
        'batches': p.batches.map((b) => b.toMap()).toList(),
      }).toList(),
      'sales': sales.map((s) => {
        ...s.toMap(),
        'items': s.items.map((i) => i.toMap()).toList(),
      }).toList(),
      'customers': customers.map((c) => {
        ...c.toMap(),
        'payments': c.payments.map((p) => p.toMap()).toList(),
      }).toList(),
      'suppliers': suppliers.map((su) => {
        ...su.toMap(),
        'transactions': su.transactions.map((t) => t.toMap()).toList(),
      }).toList(),
    };

    return jsonEncode(data);
  }
}
