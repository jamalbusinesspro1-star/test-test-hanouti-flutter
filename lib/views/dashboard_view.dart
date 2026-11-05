import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/hanouti_provider.dart';
import '../utils/theme.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HanoutiProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = [
      {
        'title': 'مبيعات اليوم',
        'value': formatMAD(provider.todayRevenue),
        'icon': LucideIcons.trendingUp,
        'bg': const Color(0xFFE8F5EE),
        'color': AppTheme.primary,
      },
      {
        'title': 'أرباح اليوم التقديرية',
        'value': formatMAD(provider.todayProfit),
        'icon': LucideIcons.coins,
        'bg': const Color(0xFFFEF3C7),
        'color': const Color(0xFFD97706),
      },
      {
        'title': 'عدد معاملات اليوم',
        'value': '${provider.todaySalesCount} عملية',
        'icon': LucideIcons.receipt,
        'bg': const Color(0xFFEFF6FF),
        'color': const Color(0xFF2563EB),
      },
      {
        'title': 'إجمالي السلع المسجلة',
        'value': '${provider.products.length} سلعة',
        'icon': LucideIcons.package,
        'bg': const Color(0xFFF3E8FF),
        'color': const Color(0xFF9333EA),
      },
      {
        'title': 'قيمة رأس مال المخزون',
        'value': formatMAD(provider.totalStockInvestment),
        'icon': LucideIcons.warehouse,
        'bg': const Color(0xFFF1F5F9),
        'color': const Color(0xFF475569),
      },
      {
        'title': 'تنبيهات تتطلب الانتباه',
        'value': '${provider.totalAlertsCount} تنبيه',
        'icon': LucideIcons.alertTriangle,
        'bg': provider.totalAlertsCount > 0 ? const Color(0xFFFEE2E2) : const Color(0xFFE8F5EE),
        'color': provider.totalAlertsCount > 0 ? AppTheme.danger : AppTheme.primary,
      },
    ];

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => provider.loadAllData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // كارت الترحيب
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryDark],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحباً بك في ${provider.settings['shopName'] ?? "حانوتي"}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'نظام تسيير الحانوت الذكي — يشتغل بدون إنترنت 100%',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // شبكة الإحصائيات (Stat Cards)
              const Text(
                'نظرة عامة على النشاط اليومي',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMain,
                ),
              ),
              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                ),
                itemCount: stats.length,
                itemBuilder: (context, index) {
                  final s = stats[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: s['bg'] as Color,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                s['icon'] as IconData,
                                color: s['color'] as Color,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s['title'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              s['value'] as String,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textMain,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
