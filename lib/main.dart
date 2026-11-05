import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'providers/hanouti_provider.dart';
import 'utils/theme.dart';
import 'views/dashboard_view.dart';
import 'views/pos_view.dart';
import 'views/products_view.dart';
import 'views/credit_view.dart';
import 'views/suppliers_view.dart';
import 'views/alerts_view.dart';
import 'views/reports_view.dart';
import 'views/settings_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HanoutiProvider()..loadAllData()),
      ],
      child: const HanoutiApp(),
    ),
  );
}

class HanoutiApp extends StatelessWidget {
  const HanoutiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'حانوتي',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('ar', 'MA'),
      supportedLocales: const [Locale('ar', 'MA')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HanoutiProvider>();
    final alertCount = provider.totalAlertsCount;

    final pages = [
      const DashboardView(),
      PosView(onSaleCompleted: () => setState(() => _currentIndex = 6)), // التحويل للتقارير بعد البيع
      const ProductsView(),
      const CreditView(),
      const SuppliersView(),
      const AlertsView(),
      const ReportsView(),
      const SettingsView(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.store, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              provider.settings['shopName'] ?? 'حانوتي',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings),
            tooltip: 'الإعدادات والنسخ الاحتياطي',
            onPressed: () => setState(() => _currentIndex = 7),
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex > 6 ? 0 : _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: [
          const NavigationDestination(
            icon: Icon(LucideIcons.layoutDashboard),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: provider.cartCount > 0,
              label: Text('${provider.cartCount}'),
              child: const Icon(LucideIcons.shoppingCart),
            ),
            label: 'نقطة البيع',
          ),
          const NavigationDestination(
            icon: Icon(LucideIcons.package),
            label: 'السلع',
          ),
          const NavigationDestination(
            icon: Icon(LucideIcons.wallet),
            label: 'الكريدي',
          ),
          const NavigationDestination(
            icon: Icon(LucideIcons.truck),
            label: 'الموردون',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: alertCount > 0,
              label: Text('$alertCount'),
              backgroundColor: AppTheme.danger,
              child: const Icon(LucideIcons.bell),
            ),
            label: 'التنبيهات',
          ),
          const NavigationDestination(
            icon: Icon(LucideIcons.fileText),
            label: 'التقارير',
          ),
        ],
      ),
    );
  }
}
