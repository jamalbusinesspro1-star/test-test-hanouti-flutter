import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/hanouti_provider.dart';
import '../utils/theme.dart';

class CreditView extends StatefulWidget {
  const CreditView({super.key});

  @override
  State<CreditView> createState() => _CreditViewState();
}

class _CreditViewState extends State<CreditView> {
  String _searchQuery = '';

  void _showAddCustomerDialog() {
    final provider = context.read<HanoutiProvider>();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final initialDebtCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('تسجيل زبون جديد في الكناش'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم الزبون *')),
                const SizedBox(height: 10),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'رقم الهاتف'), keyboardType: TextInputType.phone),
                const SizedBox(height: 10),
                TextField(controller: initialDebtCtrl, decoration: const InputDecoration(labelText: 'دين سابق إن وجد (د.م)'), keyboardType: TextInputType.number),
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
                await provider.createCustomer(nameCtrl.text.trim(), phoneCtrl.text.trim(), noteCtrl.text.trim(), debt);
                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text('حفظ الزبون'),
            ),
          ],
        );
      },
    );
  }

  void _showTransactionDialog(Customer customer, String type) {
    final provider = context.read<HanoutiProvider>();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final isPay = type == 'PAYMENT';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isPay ? 'تسجيل تسديد دفعة: ${customer.name}' : 'تسجيل دين إضافي: ${customer.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: isPay ? 'المبلغ المسدد (د.م) *' : 'مبلغ الدين الجديد (د.م) *'),
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
                await provider.addCustomerPayment(customer.id, type, amt, noteCtrl.text.trim());
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
    final filtered = provider.customers.where((c) {
      final q = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(q) || (c.phone?.contains(q) ?? false) || c.code.contains(q);
    }).toList();

    final totalDebts = provider.customers.fold(0.0, (sum, c) => sum + (c.balance > 0 ? c.balance : 0));

    return Scaffold(
      appBar: AppBar(
        title: const Text('كناش الكريدي (الزبناء)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.userPlus),
        label: const Text('زبون جديد'),
        onPressed: _showAddCustomerDialog,
      ),
      body: Column(
        children: [
          // كارت إجمالي الديون في السوق
          Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('إجمالي الكريدي فالسوق:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('مجموع المبالغ المتبقية على الزبناء', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    ],
                  ),
                  Text(
                    formatMAD(totalDebts),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'ابحث عن زبون بالاسم، الهاتف أو الكود...',
                prefixIcon: Icon(LucideIcons.search),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('لا يوجد زبناء في الكناش'))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80, left: 14, right: 14),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final c = filtered[index];
                      final hasDebt = c.balance > 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: hasDebt ? AppTheme.warningLight : AppTheme.primaryLight,
                            child: Icon(
                              LucideIcons.user,
                              color: hasDebt ? Colors.amber.shade800 : AppTheme.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('الهاتف: ${c.phone ?? "لا يوجد"} | الكود: ${c.code}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatMAD(c.balance),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: hasDebt ? Colors.amber.shade900 : AppTheme.success,
                                ),
                              ),
                              Text(hasDebt ? 'باقي عليه' : 'خالص', style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
                                          label: const Text('تسديد دفعة'),
                                          onPressed: () => _showTransactionDialog(c, 'PAYMENT'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700),
                                          icon: const Icon(LucideIcons.plus, size: 16),
                                          label: const Text('زيادة كريدي'),
                                          onPressed: () => _showTransactionDialog(c, 'DEBT'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  const Align(
                                    alignment: Alignment.centerRight,
                                    child: Text('سجل الحركات:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                  ...c.payments.map((p) {
                                    final isP = p.type == 'PAYMENT';
                                    return ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(
                                        isP ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
                                        color: isP ? AppTheme.success : AppTheme.danger,
                                        size: 18,
                                      ),
                                      title: Text('${isP ? "تسديد" : "دين"}: ${formatMAD(p.amount)}'),
                                      subtitle: Text('${DateFormat('yyyy/MM/dd HH:mm').format(p.createdAt)} ${p.note != null ? "(${p.note})" : ""}'),
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
