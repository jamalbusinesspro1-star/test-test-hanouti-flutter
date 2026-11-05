import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../providers/hanouti_provider.dart';
import '../utils/theme.dart';

class AlertsView extends StatelessWidget {
  const AlertsView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HanoutiProvider>();
    final expired = provider.expiredBatches;
    final expiringSoon = provider.expiringSoonBatches;
    final outOfStock = provider.outOfStockProducts;
    final lowStock = provider.lowStockProducts;

    final hasNoAlerts = expired.isEmpty && expiringSoon.isEmpty && outOfStock.isEmpty && lowStock.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('مركز التنبيهات الذكي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: hasNoAlerts
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.checkCircle2, size: 64, color: AppTheme.success.withValues(alpha: 0.5)),
                  const SizedBox(height: 14),
                  const Text('لا توجد أي تنبيهات حالياً', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('كل السلع والمخزون في وضعية ممتازة', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(14),
              children: [
                if (expired.isNotEmpty) ...[
                  _buildSectionHeader('سلع منتهية الصلاحية تماماً', LucideIcons.alertCircle, AppTheme.danger),
                  ...expired.map((item) {
                    final p = item['product'];
                    final b = item['batch'];
                    return Card(
                      color: AppTheme.dangerLight,
                      child: ListTile(
                        leading: const Icon(LucideIcons.xCircle, color: AppTheme.danger),
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.danger)),
                        subtitle: Text('الكمية المتبقية: ${formatQty(b.quantity, p.unitType)} | انتهت في: ${DateFormat('yyyy/MM/dd').format(b.expiryDate)}'),
                        trailing: IconButton(
                          icon: const Icon(LucideIcons.trash2, color: AppTheme.danger),
                          tooltip: 'إتلاف الدفعة المنتهية',
                          onPressed: () => provider.deleteBatch(b.id),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],

                if (expiringSoon.isNotEmpty) ...[
                  _buildSectionHeader('سلع تقترب من نهاية الصلاحية (خلال 30 يوم)', LucideIcons.clock, AppTheme.warning),
                  ...expiringSoon.map((item) {
                    final p = item['product'];
                    final b = item['batch'];
                    final days = item['daysLeft'];
                    return Card(
                      color: AppTheme.warningLight,
                      child: ListTile(
                        leading: const Icon(LucideIcons.alertTriangle, color: AppTheme.warning),
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                        subtitle: Text('الكمية: ${formatQty(b.quantity, p.unitType)} | متبقي: $days يوم (${DateFormat('yyyy/MM/dd').format(b.expiryDate)})'),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],

                if (outOfStock.isNotEmpty) ...[
                  _buildSectionHeader('سلع نفدت من المخزون تماماً', LucideIcons.packageX, Colors.red.shade800),
                  ...outOfStock.map((p) {
                    return Card(
                      child: ListTile(
                        leading: const Icon(LucideIcons.packageX, color: AppTheme.danger),
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('المخزون الحالي: 0'),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],

                if (lowStock.isNotEmpty) ...[
                  _buildSectionHeader('سلع مخزونها قليل (5 وحدات أو أقل)', LucideIcons.package, Colors.orange),
                  ...lowStock.map((p) {
                    return Card(
                      child: ListTile(
                        leading: const Icon(LucideIcons.packageOpen, color: Colors.orange),
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('المتبقي فقط: ${formatQty(p.totalStock, p.unitType)}'),
                      ),
                    );
                  }),
                ],
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        ],
      ),
    );
  }
}
