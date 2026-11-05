import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/models.dart';
import '../providers/hanouti_provider.dart';
import '../utils/theme.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  DateTime _selectedDate = DateTime.now();

  void _printReceipt(Sale sale) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('حانوتي', style: const pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text('توصيل مبيعات / فاتورة', style: const pw.TextStyle(fontSize: 10)),
              pw.Divider(),
              pw.Text('التاريخ: ${DateFormat('yyyy/MM/dd HH:mm').format(sale.createdAt)}', style: const pw.TextStyle(fontSize: 8)),
              pw.Divider(),
              pw.ListView.builder(
                itemCount: sale.items.length,
                itemBuilder: (context, index) {
                  final it = sale.items[index];
                  return pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(it.productName, style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('${it.quantity} x ${it.unitPrice} = ${it.total} د.م', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  );
                },
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('المجموع الإجمالي:', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text('${sale.total} د.م', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ],
              ),
              if (sale.change > 0) ...[
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('الباقي:', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('${sale.change} د.م', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ],
              pw.SizedBox(height: 10),
              pw.Text('شكراً لزيارتكم!', style: const pw.TextStyle(fontSize: 9)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HanoutiProvider>();
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final daySales = provider.sales.where((s) => s.createdAt.toIso8601String().startsWith(dateStr)).toList();
    final dayRevenue = daySales.fold(0.0, (sum, s) => sum + s.total);

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل المبيعات والتقارير', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Column(
        children: [
          // شريط اختيار اليوم
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(LucideIcons.calendar, color: AppTheme.primary),
                    title: const Text('تاريخ التقرير:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    subtitle: Text(
                      DateFormat('yyyy/MM/dd').format(_selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('مداخيل اليوم:', style: TextStyle(fontSize: 10, color: AppTheme.primaryDark)),
                      Text(
                        formatMAD(dayRevenue),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: daySales.isEmpty
                ? const Center(child: Text('لا توجد مبيعات مسجلة في هذا اليوم'))
                : ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: daySales.length,
                    itemBuilder: (context, index) {
                      final s = daySales[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ExpansionTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppTheme.primaryLight,
                            child: Icon(LucideIcons.receipt, color: AppTheme.primary, size: 20),
                          ),
                          title: Text(
                            'معاملة: ${formatMAD(s.total)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          subtitle: Text('الوقت: ${DateFormat('HH:mm').format(s.createdAt)} | عدد العناصر: ${s.items.length}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.printer, color: AppTheme.primary, size: 20),
                                tooltip: 'طباعة الوصل',
                                onPressed: () => _printReceipt(s),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.trash2, color: AppTheme.danger, size: 18),
                                tooltip: 'إلغاء المعاملة وإرجاع السلع',
                                onPressed: () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('تأكيد الإلغاء'),
                                      content: const Text('سيتم حذف المعاملة وإعادة كميات السلع إلى المخزون.'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('رجوع')),
                                        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تأكيد الإلغاء')),
                                      ],
                                    ),
                                  );
                                  if (ok == true) {
                                    await provider.deleteSale(s.id);
                                  }
                                },
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Column(
                                children: s.items.map((it) {
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${it.productName} (${formatQty(it.quantity, it.unitType)})'),
                                      Text(formatMAD(it.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  );
                                }).toList(),
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
