# حانوتي — تطبيق Flutter & Dart (Native Android/iOS)

تمت إعادة هندسة وبرمجة تطبيق **حانوتي** من مشروع Next.js/Web إلى تطبيق **Flutter/Dart Native** متكامل ونظيف 100%.

---

## 🏗️ البنية المعمارية للمشروع الجديد (`hanouti-flutter`)

```text
hanouti-flutter/
├── pubspec.yaml                  # التبعات (sqflite, provider, mobile_scanner, pdf, printing, ...)
└── lib/
    ├── main.dart                 # نقطة الانطلاق + Shell Navigation السفلي
    ├── database/
    │   └── local_database.dart   # قاعدة بيانات SQLite محلية بالكامل (FIFO + Transactions)
    ├── models/
    │   └── models.dart           # نماذج البيانات (Product, Batch, Sale, Customer, Supplier)
    ├── providers/
    │   └── hanouti_provider.dart # إدارة الحالة والتفاعل (State Management بـ Provider)
    ├── utils/
    │   └── theme.dart            # الهوية البصرية (اللون #2f9e5f، الدرهم المغربي، الخطوط)
    └── views/
        ├── dashboard_view.dart   # لوحة التحكم والإحصائيات والأرباح اليومية
        ├── pos_view.dart         # شاشة نقطة البيع (POS) والسلة وطرق الدفع (كاش/كريدي)
        ├── products_view.dart    # إدارة السلع والمخزون والدفعات وتواريخ الصلاحية
        ├── credit_view.dart      # كناش الكريدي (الزبناء، الديون، التسديدات)
        ├── suppliers_view.dart   # حسابات الموردين وتتبع الفواتير والأداءات
        ├── alerts_view.dart      # التنبيهات الذكية (انتهاء الصلاحية ونفاد المخزون)
        ├── reports_view.dart     # سجل المبيعات والتقارير وطباعة وصل البيع PDF
        ├── settings_view.dart    # إعدادات الحانوت وتصدير النسخة الاحتياطية
        └── barcode_scanner_dialog.dart # سكانير الكاميرا المباشر لقراءة الباركود
```

---

## 🚀 كيفية تشغيل وبناء الـ APK:

بمجرد توفر Flutter SDK على جهازك:

1. الدخول للمجلد:
```powershell
cd "C:\Users\HP\.gemini\antigravity\scratch\hanouti-flutter"
```

2. جلب الحزم:
```powershell
flutter pub get
```

3. تشغيل التطبيق محلياً:
```powershell
flutter run
```

4. استخراج ملف APK مباشر:
```powershell
flutter build apk --release
```
ستجد الملف الناتج في: `build/app/outputs/flutter-apk/app-release.apk`
