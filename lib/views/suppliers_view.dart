import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/hanouti_provider.dart';
import '../utils/theme.dart';

class SuppliersView extends StatefulWidget {
  const SuppliersView({super.key});

  @override
  State<SuppliersView> createState() => _SuppliersViewState();
}

class _SuppliersViewState extends State<SuppliersView> {
  String _searchQuery = '';

  void _showAddSupplierDialog() {
    final provider = context.read<HanoutiProvider>();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final initialDebtCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('تسجيل مورد جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم المورد أو الشركة *')),
                const SizedBox(height: 10),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'رقم الهاتف'), keyboardType: TextInputType.phone),
                const SizedBox(height: 10),
                TextField(controller: initialDebtCtrl, decoration: const InputDecoration(labelText: 'مبلغ علينا للمورد (د.م)'), keyboardType: TextInputType.number),
                const SizedBox(height: 10),
                TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'ملاحظة')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final debt = double.tryParse(initialDebtCtrl.text) ?? 0.0;
                await provider.createSupplier(nameCtrl.text.trim(), phoneCtrl.text.trim(), noteCtrl.text.trim(), debt);
                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text('حفظ المورد'),
            ),
          ],
        );
      },
    );
  }

  void _showTransactionDialog(Supplier supplier, String type) {
    final provider = context.read<HanoutiProvider>();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final isPay = type == 'PAYMENT';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isPay ? 'تسجيل أداء للمورد: ${supplier.name}' : 'تسجيل فاتورة جديدة: ${supplier.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: isPay ? 'المبلغ المؤدى له (د.م) *' : 'مبلغ الفاتورة (د.م) *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'ملاحظة (اختياري)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(amountCtrl.text) ?? 0.0;
                if (amt <= 0) return;
                await provider.addSupplierTransaction(supplier.id, type, amt, noteCtrl.text.trim());
                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text('تأكيد'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HanoutiProvider>();
    final filtered = provider.suppliers.where((s) {
      final q = _searchQuery.toLowerCase();
      return s.name.toLowerCase().contains(q) || (s.phone?.contains(q) ?? false);
    }).toList();

    final totalOwed = provider.suppliers.fold(0.0, (sum, s) => sum + (s.balance > 0 ? s.balance : 0));

    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابات الموردين', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.truck),
        label: const Text('مورد جديد'),
        onPressed: _showAddSupplierDialog,
      ),
      body: Column(
        children: [
          // كارت إجمالي مستحقات الموردين
          Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('إجمالي مستحقات الموردين:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('مجموع المبالغ المتبقية علينا للموردين', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    ],
                  ),
                  Text(
                    formatMAD(totalOwed),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'ابحث عن مورد بالاسم أو الهاتف...',
                prefixIcon: Icon(LucideIcons.search),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('لا يوجد موردون مسجلون'))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80, left: 14, right: 14),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final s = filtered[index];
                      final owesMoney = s.balance > 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Icon(LucideIcons.truck, color: Colors.blue.shade800, size: 20),
                          ),
                          title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('الهاتف: ${s.phone ?? "لا يوجد"}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatMAD(s.balance),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: owesMoney ? AppTheme.danger : AppTheme.success,
                                ),
                              ),
                              Text(owesMoney ? 'كنسالوه / كيسالنا' : 'خالص', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            icon: const Icon(LucideIcons.hand, size: 16),
                                          label: const Text('أداء دفعة'),
                                          onPressed: () => _showTransactionDialog(s, 'PAYMENT'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
                                          icon: const Icon(LucideIcons.plus, size: 16),
                                          label: const Text('فاتورة سلعة'),
                                          onPressed: () => _showTransactionDialog(s, 'DEBT'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  const Align(
                                    alignment: Alignment.centerRight,
                                    child: Text('سجل المعاملات مع المورد:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                  ...s.transactions.map((t) {
                                    final isP = t.type == 'PAYMENT';
                                    return ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(
                                        isP ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
                                        color: isP ? AppTheme.success : AppTheme.danger,
                                        size: 18,
                                      ),
                                      title: Text('${isP ? "أداء من طرفنا" : "فاتورة سلعة"}: ${formatMAD(t.amount)}'),
                                      subtitle: Text('${DateFormat('yyyy/MM/dd HH:mm').format(t.createdAt)} ${t.note != null ? "(${t.note})" : ""}'),
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
