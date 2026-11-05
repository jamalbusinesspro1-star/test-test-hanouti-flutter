import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/local_database.dart';

class HanoutiProvider with ChangeNotifier {
  final LocalDatabase _db = LocalDatabase.instance;

  List<Product> _products = [];
  List<Sale> _sales = [];
  List<Customer> _customers = [];
  List<Supplier> _suppliers = [];
  Map<String, String> _settings = {'shopName': 'حانوتي', 'ownerName': 'مول الحانوت'};
  bool _isLoading = true;

  // سلة المبيعات (Cart)
  final List<CartItemModel> _cart = [];

  List<Product> get products => _products;
  List<Sale> get sales => _sales;
  List<Customer> get customers => _customers;
  List<Supplier> get suppliers => _suppliers;
  Map<String, String> get settings => _settings;
  bool get isLoading => _isLoading;
  List<CartItemModel> get cart => _cart;

  double get cartTotal => _cart.fold(0.0, (sum, it) => sum + it.total);
  int get cartCount => _cart.length;

  // إحصائيات لوحة التحكم اليومية
  double get todayRevenue {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return _sales
        .where((s) => s.createdAt.toIso8601String().substring(0, 10) == today)
        .fold(0.0, (sum, s) => sum + s.total);
  }

  int get todaySalesCount {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return _sales
        .where((s) => s.createdAt.toIso8601String().substring(0, 10) == today)
        .length;
  }

  double get todayProfit {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final todaySales = _sales
        .where((s) => s.createdAt.toIso8601String().substring(0, 10) == today);
    double profit = 0.0;
    for (var s in todaySales) {
      for (var it in s.items) {
        profit += (it.unitPrice - it.purchasePrice) * it.quantity;
      }
    }
    return profit;
  }

  double get totalStockInvestment {
    return _products.fold(0.0, (sum, p) => sum + p.totalInvestment);
  }

  // التنبيهات
  List<Map<String, dynamic>> get expiredBatches {
    final now = DateTime.now();
    final list = <Map<String, dynamic>>[];
    for (var p in _products) {
      for (var b in p.batches) {
        if (b.quantity > 0 && b.expiryDate.isBefore(now)) {
          final days = b.expiryDate.difference(now).inDays;
          list.add({
            'product': p,
            'batch': b,
            'daysLeft': days,
          });
        }
      }
    }
    return list;
  }

  List<Map<String, dynamic>> get expiringSoonBatches {
    final now = DateTime.now();
    final after30Days = now.add(const Duration(days: 30));
    final list = <Map<String, dynamic>>[];
    for (var p in _products) {
      for (var b in p.batches) {
        if (b.quantity > 0 &&
            b.expiryDate.isAfter(now) &&
            b.expiryDate.isBefore(after30Days)) {
          final days = b.expiryDate.difference(now).inDays;
          list.add({
            'product': p,
            'batch': b,
            'daysLeft': days,
          });
        }
      }
    }
    return list;
  }

  List<Product> get outOfStockProducts {
    return _products.where((p) => p.totalStock <= 0).toList();
  }

  List<Product> get lowStockProducts {
    return _products.where((p) => p.totalStock > 0 && p.totalStock <= 5).toList();
  }

  int get totalAlertsCount =>
      expiredBatches.length +
      expiringSoonBatches.length +
      outOfStockProducts.length +
      lowStockProducts.length;

  Future<void> loadAllData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _products = await _db.getProducts();
      _sales = await _db.getSales();
      _customers = await _db.getCustomers();
      _suppliers = await _db.getSuppliers();
      _settings = await _db.getSettings();
    } catch (e) {
      debugPrint("Error loading data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // إدارة السلة
  void addToCart(Product product, {double qty = 1.0}) {
    final index = _cart.indexWhere((it) => it.productId == product.id);
    if (index >= 0) {
      _cart[index].quantity += qty;
    } else {
      _cart.add(CartItemModel(
        productId: product.id,
        productName: product.name,
        unitType: product.unitType,
        quantity: qty,
        unitPrice: product.currentSalePrice,
      ));
    }
    notifyListeners();
  }

  void updateCartQty(String productId, double qty) {
    final index = _cart.indexWhere((it) => it.productId == productId);
    if (index >= 0) {
      if (qty <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index].quantity = qty;
      }
      notifyListeners();
    }
  }

  void updateCartPrice(String productId, double price) {
    final index = _cart.indexWhere((it) => it.productId == productId);
    if (index >= 0) {
      _cart[index].unitPrice = price;
      notifyListeners();
    }
  }

  void removeFromCart(String productId) {
    _cart.removeWhere((it) => it.productId == productId);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  // إتمام عملية البيع
  Future<Sale> completeSale({
    required double amountPaid,
    String? customerId,
  }) async {
    final sale = await _db.createSale(
      items: List.from(_cart),
      amountPaid: amountPaid,
      customerId: customerId,
    );
    _cart.clear();
    await loadAllData();
    return sale;
  }

  Future<void> deleteSale(String saleId) async {
    await _db.deleteSale(saleId);
    await loadAllData();
  }

  // إضافة وتعديل السلع
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
    await _db.createProduct(
      name: name,
      unitType: unitType,
      quantity: quantity,
      purchasePrice: purchasePrice,
      salePrice: salePrice,
      expiryDate: expiryDate,
      barcode: barcode,
      supplierId: supplierId,
      contains: contains,
      packUnit: packUnit,
    );
    await loadAllData();
  }

  Future<void> updateProduct(String id, String name, String? barcode, String unitType) async {
    await _db.updateProduct(id, name, barcode, unitType);
    await loadAllData();
  }

  Future<void> deleteProduct(String id) async {
    await _db.deleteProduct(id);
    await loadAllData();
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
    await _db.addBatch(
      productId: productId,
      quantity: quantity,
      purchasePrice: purchasePrice,
      salePrice: salePrice,
      expiryDate: expiryDate,
      supplierId: supplierId,
      contains: contains,
      packUnit: packUnit,
    );
    await loadAllData();
  }

  Future<void> updateBatch(Batch b) async {
    await _db.updateBatch(b);
    await loadAllData();
  }

  Future<void> deleteBatch(String batchId) async {
    await _db.deleteBatch(batchId);
    await loadAllData();
  }

  // الزبناء
  Future<void> createCustomer(String name, String? phone, String? note, double initialDebt) async {
    await _db.createCustomer(name, phone, note, initialDebt);
    await loadAllData();
  }

  Future<void> addCustomerPayment(String customerId, String type, double amount, String? note) async {
    await _db.addCustomerPayment(customerId, type, amount, note);
    await loadAllData();
  }

  Future<void> deleteCustomer(String customerId) async {
    await _db.deleteCustomer(customerId);
    await loadAllData();
  }

  // الموردون
  Future<void> createSupplier(String name, String? phone, String? note, double initialDebt) async {
    await _db.createSupplier(name, phone, note, initialDebt);
    await loadAllData();
  }

  Future<void> addSupplierTransaction(String supplierId, String type, double amount, String? note) async {
    await _db.addSupplierTransaction(supplierId, type, amount, note);
    await loadAllData();
  }

  Future<void> deleteSupplier(String supplierId) async {
    await _db.deleteSupplier(supplierId);
    await loadAllData();
  }

  // الإعدادات
  Future<void> updateShopSettings(String shopName, String ownerName, String ownerPhone) async {
    await _db.updateSetting('shopName', shopName);
    await _db.updateSetting('ownerName', ownerName);
    await _db.updateSetting('ownerPhone', ownerPhone);
    _settings['shopName'] = shopName;
    _settings['ownerName'] = ownerName;
    _settings['ownerPhone'] = ownerPhone;
    notifyListeners();
  }
}
