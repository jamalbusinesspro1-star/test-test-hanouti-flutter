import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/hanouti_provider.dart';
import '../database/local_database.dart';
import '../utils/theme.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _shopNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _ownerPhoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final p = context.read<HanoutiProvider>();
    _shopNameCtrl.text = p.settings['shopName'] ?? 'حانوتي';
    _ownerNameCtrl.text = p.settings['ownerName'] ?? 'مول الحانوت';
    _ownerPhoneCtrl.text = p.settings['ownerPhone'] ?? '';
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _ownerPhoneCtrl.dispose();
    super.dispose();
  }

  void _exportBackup() async {
    final jsonStr = await LocalDatabase.instance.exportBackupJson();
    await Share.share(jsonStr, subject: 'نسخة احتياطية حانوتي');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HanoutiProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات الحانوت والتخزين', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // بطاقة النسخ الاحتياطي
          Card(
            color: AppTheme.primaryLight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(LucideIcons.hardDrive, color: AppTheme.primary),
                      SizedBox(width: 8),
                      Text('تخزين محلي 100% بدون إنترنت', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'جميع بياناتك (السلع، المبيعات، كناش الكريدي، والموردين) محفوظة داخل جهازك مباشرة.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    icon: const Icon(LucideIcons.download),
                    label: const Text('تصدير نسخة احتياطية (مشاركة/واتساب)'),
                    onPressed: _exportBackup,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text('معلومات المتجر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          TextField(
            controller: _shopNameCtrl,
            decoration: const InputDecoration(labelText: 'اسم الحانوت'),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _ownerNameCtrl,
            decoration: const InputDecoration(labelText: 'اسم صاحب الحانوت'),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _ownerPhoneCtrl,
            decoration: const InputDecoration(labelText: 'رقم الهاتف'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () async {
              await provider.updateShopSettings(
                _shopNameCtrl.text.trim(),
                _ownerNameCtrl.text.trim(),
                _ownerPhoneCtrl.text.trim(),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حفظ الإعدادات بنجاح'), backgroundColor: AppTheme.success),
                );
              }
            },
            child: const Text('حفظ التعديلات'),
          ),
        ],
      ),
    );
  }
}
