import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/models.dart';
import '../providers/hanouti_provider.dart';
import '../utils/theme.dart';
import 'barcode_scanner_dialog.dart';

class PosView extends StatefulWidget {
  final VoidCallback onSaleCompleted;

  const PosView({super.key, required this.onSaleCompleted});

  @override
  State<PosView> createState() => _PosViewState();
}

class _PosViewState extends State<PosView> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _amountPaidCtrl = TextEditingController();
  String? _selectedCustomerId;
  Customer? _selectedCustomer;

  final List<double> _quickAmounts = [10, 20, 50, 100, 200];

  @override
  void dispose() {
    _searchCtrl.dispose();
    _amountPaidCtrl.dispose();
    super.dispose();
  }

  void _openScanner() async {
    final barcode = await showDialog<String>(
      context: context,
      builder: (ctx) => const BarcodeScannerDialog(),
    );

    if (barcode != null && barcode.isNotEmpty && mounted) {
      final provider = context.read<HanoutiProvider>();
      try {
        final prod = provider.products.firstWhere(
          (p) => p.barcode?.trim() == barcode.trim(),
        );
        provider.addToCart(prod);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تمت إضافة: ${prod.name}'),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 1),
          ),
        );
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('السلعة غير موجودة بالباركود: $barcode'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  void _showCheckoutDialog() {
    final provider = context.read<HanoutiProvider>();
    final total = provider.cartTotal;
    _amountPaidCtrl.text = total.toStringAsFixed(2);
    _selectedCustomerId = null;
    _selectedCustomer = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isCredit = _selectedCustomerId != null;
            final paid = double.tryParse(_amountPaidCtrl.text) ?? 0.0;
            final change = isCredit ? 0.0 : (paid >= total ? paid - total : 0.0);

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 16,
                right: 16,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'إتمام عملية البيع',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),

                  // إجمالي الفاتورة
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المجموع الإجمالي:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          formatMAD(total),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // خيار الكريدي / نقداً
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('نقداً (كاش)')),
                          selected: !isCredit,
                          onSelected: (val) {
                            if (val) {
                              setModalState(() {
                                _selectedCustomerId = null;
                                _selectedCustomer = null;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('كريدي (كناش)')),
                          selected: isCredit,
                          onSelected: (val) {
                            if (val) {
                              _pickCustomer(setModalState);
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  if (isCredit && _selectedCustomer != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        border: Border.all(color: Colors.amber.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.user, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'الزبون: ${_selectedCustomer!.name} (الحساب السابق: ${formatMAD(_selectedCustomer!.balance)})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              setModalState(() {
                                _selectedCustomerId = null;
                                _selectedCustomer = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (!isCredit) ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: _amountPaidCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'المبلغ المدفوع من الزبون',
                        prefixIcon: Icon(LucideIcons.banknote),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 8),

                    // أزرار المبالغ السريعة
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _quickAmounts.map((amt) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: ActionChip(
                              label: Text('${amt.toInt()} د.م'),
                              onPressed: () {
                                _amountPaidCtrl.text = amt.toString();
                                setModalState(() {});
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // الباقي (الصرف)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('الباقي للزبون (الصرف):', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          formatMAD(change),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: change < 0 ? AppTheme.danger : AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: (!isCredit && paid < total)
                        ? null
                        : () async {
                            try {
                              await provider.completeSale(
                                amountPaid: isCredit ? 0.0 : paid,
                                customerId: _selectedCustomerId,
                              );
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                              }
                              widget.onSaleCompleted();
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text('خطأ: $e'), backgroundColor: AppTheme.danger),
                                );
                              }
                            }
                          },
                    child: const Text('تأكيد وحفظ المعاملة'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _pickCustomer(StateSetter setModalState) async {
    final provider = context.read<HanoutiProvider>();
    final customers = provider.customers;

    final picked = await showDialog<Customer>(
      context: context,
      builder: (ctx) {
        String filter = '';
        return StatefulBuilder(
          builder: (context, setFilterState) {
            final filtered = customers
                .where((c) => c.name.toLowerCase().contains(filter.toLowerCase()) || c.code.contains(filter))
                .toList();

            return AlertDialog(
              title: const Text('اختر الزبون من الكناش'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'ابحث بالاسم أو الكود...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) => setFilterState(() => filter = v),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final c = filtered[index];
                          return ListTile(
                            title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('الرصيد: ${formatMAD(c.balance)}'),
                            onTap: () => Navigator.pop(ctx, c),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (picked != null) {
      setModalState(() {
        _selectedCustomerId = picked.id;
        _selectedCustomer = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HanoutiProvider>();
    final cart = provider.cart;
    final total = provider.cartTotal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('معاملة بيع جديدة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.scanLine, color: AppTheme.primary),
            tooltip: 'مسح الباركود بالكاميرا',
            onPressed: _openScanner,
          ),
          if (cart.isNotEmpty)
            IconButton(
              icon: const Icon(LucideIcons.trash2, color: AppTheme.danger),
              tooltip: 'تفريغ السلة',
              onPressed: () => provider.clearCart(),
            ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث لاختيار سلعة يدوياً
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Autocomplete<Product>(
              displayStringForOption: (p) => p.name,
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) return const Iterable<Product>.empty();
                return provider.products.where((p) =>
                    p.name.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                    (p.barcode?.contains(textEditingValue.text) ?? false));
              },
              onSelected: (p) {
                provider.addToCart(p);
                _searchCtrl.clear();
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن السلعة بالاسم أو الباركود...',
                    prefixIcon: const Icon(LucideIcons.search, size: 20),
                    suffixIcon: IconButton(
                      icon: const Icon(LucideIcons.scanLine, color: AppTheme.primary),
                      onPressed: _openScanner,
                    ),
                  ),
                );
              },
            ),
          ),

          // قائمة السلع في السلة
          Expanded(
            child: cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.shoppingCart, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text(
                          'السلة فارغة حالياً',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'امسح الباركود أو ابحث عن سلعة لإضافتها',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: cart.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${formatMAD(item.unitPrice)} للـ ${unitLabel(item.unitType)}',
                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            // أزرار الزيادة والنقصان
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: AppTheme.danger),
                                  onPressed: () => provider.updateCartQty(item.productId, item.quantity - 1),
                                ),
                                Text(
                                  formatQty(item.quantity, item.unitType),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                                  onPressed: () => provider.updateCartQty(item.productId, item.quantity + 1),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              formatMAD(item.total),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // الشريط السفلي: المجموع وزر إنهاء المعاملة
          if (cart.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -3)),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('المجموع:', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        Text(
                          formatMAD(total),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      icon: const Icon(LucideIcons.checkCircle2),
                      label: const Text('دفع وإنهاء (FOD)'),
                      onPressed: _showCheckoutDialog,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
