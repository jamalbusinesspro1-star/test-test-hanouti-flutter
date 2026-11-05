import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/hanouti_provider.dart';
import '../utils/theme.dart';
import 'barcode_scanner_dialog.dart';

class ProductsView extends StatefulWidget {
  const ProductsView({super.key});

  @override
  State<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<ProductsView> {
  String _searchQuery = '';

  void _showAddProductDialog([Product? existingProduct]) {
    final provider = context.read<HanoutiProvider>();
    final isEdit = existingProduct != null;

    final nameCtrl = TextEditingController(text: existingProduct?.name ?? '');
    final barcodeCtrl = TextEditingController(text: existingProduct?.barcode ?? '');
    String unitType = existingProduct?.unitType ?? 'PIECE';

    final qtyCtrl = TextEditingController(text: '1');
    final purchasePriceCtrl = TextEditingController();
    final salePriceCtrl = TextEditingController();
    DateTime expiryDate = DateTime.now().add(const Duration(days: 180));
    String? selectedSupplierId;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(isEdit ? 'تعديل السلعة' : 'إضافة سلعة جديدة'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'اسم السلعة *'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: barcodeCtrl,
                            decoration: const InputDecoration(labelText: 'الباركود (اختياري)'),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.scanLine, color: AppTheme.primary),
                          onPressed: () async {
                            final code = await showDialog<String>(
                              context: context,
                              builder: (_) => const BarcodeScannerDialog(),
                            );
                            if (code != null) {
                              setModalState(() => barcodeCtrl.text = code);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: unitType,
                      decoration: const InputDecoration(labelText: 'نوع الوحدة'),
                      items: const [
                        DropdownMenuItem(value: 'PIECE', child: Text('حبة')),
                        DropdownMenuItem(value: 'KILO', child: Text('كيلو')),
                        DropdownMenuItem(value: 'LITER', child: Text('لتر')),
                      ],
                      onChanged: (v) => setModalState(() => unitType = v!),
                    ),

                    // في حالة السلعة الجديدة: إضافة دفعة أولى
                    if (!isEdit) ...[
                      const SizedBox(height: 14),
                      const Divider(),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text('معلومات الدفعة الأولى المخزنية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: qtyCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'الكمية *'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: purchasePriceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'ثمن الشراء *'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: salePriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'ثمن البيع *'),
                      ),
                      const SizedBox(height: 10),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('تاريخ انتهاء الصلاحية'),
                        subtitle: Text(DateFormat('yyyy/MM/dd').format(expiryDate)),
                        trailing: const Icon(LucideIcons.calendar),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: expiryDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                          );
                          if (picked != null) {
                            setModalState(() => expiryDate = picked);
                          }
                        },
                      ),
                      DropdownButtonFormField<String?>(
                        initialValue: selectedSupplierId,
                        decoration: const InputDecoration(labelText: 'المورد (اختياري)'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('بدون مورد')),
                          ...provider.suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                        ],
                        onChanged: (v) => setModalState(() => selectedSupplierId = v),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    if (isEdit) {
                      await provider.updateProduct(
                        existingProduct.id,
                        nameCtrl.text.trim(),
                        barcodeCtrl.text.trim().isEmpty ? null : barcodeCtrl.text.trim(),
                        unitType,
                      );
                    } else {
                      final qty = double.tryParse(qtyCtrl.text) ?? 1.0;
                      final buy = double.tryParse(purchasePriceCtrl.text) ?? 0.0;
                      final sale = double.tryParse(salePriceCtrl.text) ?? 0.0;

                      await provider.createProduct(
                        name: nameCtrl.text.trim(),
                        unitType: unitType,
                        quantity: qty,
                        purchasePrice: buy,
                        salePrice: sale,
                        expiryDate: expiryDate,
                        barcode: barcodeCtrl.text.trim().isEmpty ? null : barcodeCtrl.text.trim(),
                        supplierId: selectedSupplierId,
                      );
                    }
                    if (context.mounted) Navigator.pop(ctx);
                  },
                  child: Text(isEdit ? 'تعديل' : 'حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddBatchDialog(Product product) {
    final provider = context.read<HanoutiProvider>();
    final qtyCtrl = TextEditingController(text: '1');
    final purchasePriceCtrl = TextEditingController(text: product.currentPurchasePrice.toString());
    final salePriceCtrl = TextEditingController(text: product.currentSalePrice.toString());
    DateTime expiryDate = DateTime.now().add(const Duration(days: 180));
    String? selectedSupplierId;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text('تزويد دفعة مخزون: ${product.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'الكمية المضافة *'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: purchasePriceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'ثمن الشراء للوحدة *'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: salePriceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'ثمن البيع للوحدة *'),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('تاريخ انتهاء الصلاحية'),
                      subtitle: Text(DateFormat('yyyy/MM/dd').format(expiryDate)),
                      trailing: const Icon(LucideIcons.calendar),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: expiryDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                        );
                        if (picked != null) {
                          setModalState(() => expiryDate = picked);
                        }
                      },
                    ),
                    DropdownButtonFormField<String?>(
                      initialValue: selectedSupplierId,
                      decoration: const InputDecoration(labelText: 'المورد (اختياري)'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('بدون مورد')),
                        ...provider.suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                      ],
                      onChanged: (v) => setModalState(() => selectedSupplierId = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                ElevatedButton(
                  onPressed: () async {
                    final qty = double.tryParse(qtyCtrl.text) ?? 1.0;
                    final buy = double.tryParse(purchasePriceCtrl.text) ?? 0.0;
                    final sale = double.tryParse(salePriceCtrl.text) ?? 0.0;

                    await provider.addBatch(
                      productId: product.id,
                      quantity: qty,
                      purchasePrice: buy,
                      salePrice: sale,
                      expiryDate: expiryDate,
                      supplierId: selectedSupplierId,
                    );
                    if (context.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('إضافة الدفعة'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HanoutiProvider>();
    final filtered = provider.products.where((p) {
      final q = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) || (p.barcode?.contains(q) ?? false);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة السلع والمخزون', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plus),
        label: const Text('سلعة جديدة'),
        onPressed: () => _showAddProductDialog(),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'ابحث عن سلعة بالاسم أو الباركود...',
                prefixIcon: Icon(LucideIcons.search),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('لا توجد سلع مطابقة'))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80, left: 14, right: 14, top: 6),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final p = filtered[index];
                      final isLow = p.totalStock <= 5;
                      final isOut = p.totalStock <= 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ExpansionTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isOut
                                  ? AppTheme.dangerLight
                                  : (isLow ? AppTheme.warningLight : AppTheme.primaryLight),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              LucideIcons.package,
                              color: isOut
                                  ? AppTheme.danger
                                  : (isLow ? AppTheme.warning : AppTheme.primary),
                              size: 22,
                            ),
                          ),
                          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            'المخزون: ${formatQty(p.totalStock, p.unitType)} | البيع: ${formatMAD(p.currentSalePrice)}',
                            style: TextStyle(
                              color: isOut ? AppTheme.danger : (isLow ? AppTheme.warning : AppTheme.textMuted),
                              fontSize: 12,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.plusCircle, color: AppTheme.primary),
                                tooltip: 'تزويد دفعة',
                                onPressed: () => _showAddBatchDialog(p),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.edit2, size: 18),
                                onPressed: () => _showAddProductDialog(p),
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('الباركود: ${p.barcode ?? "غير مسجل"}', style: const TextStyle(fontSize: 12)),
                                      TextButton.icon(
                                        icon: const Icon(LucideIcons.trash2, size: 16, color: AppTheme.danger),
                                        label: const Text('حذف السلعة', style: TextStyle(color: AppTheme.danger, fontSize: 12)),
                                        onPressed: () async {
                                          final ok = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('تأكيد الحذف'),
                                              content: Text('هل أنت متأكد من حذف ${p.name} وجميع دفعاتها؟'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                                                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف')),
                                              ],
                                            ),
                                          );
                                          if (ok == true) {
                                            await provider.deleteProduct(p.id);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  const Divider(),
                                  const Text('الدفعات المخزنية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ...p.batches.map((b) {
                                    return ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text('الكمية: ${formatQty(b.quantity, p.unitType)} (شراء: ${formatMAD(b.purchasePrice)} | بيع: ${formatMAD(b.salePrice)})'),
                                      subtitle: Text('الصلاحية: ${DateFormat('yyyy/MM/dd').format(b.expiryDate)}'),
                                      trailing: IconButton(
                                        icon: const Icon(LucideIcons.trash, size: 16, color: Colors.grey),
                                        onPressed: () => provider.deleteBatch(b.id),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
