# إصلاح تعارض إصدار Android SDK ومشكلات البناء

يهدف هذا الإصلاح إلى حل مشكلة توقف بناء التطبيق الناتجة عن تطلب مكتبة `flutter_secure_storage` لإصدار Android SDK 37، بينما المشروع مهيأ حالياً للإصدار 36. كما سيعالج مشكلات التخزين المؤقت لـ Kotlin.

## التغييرات المقترحة

### أندرويد (Android Configuration)

#### [MODIFY] [build.gradle.kts](file:///E:/repo/nova_modest/android/app/build.gradle.kts)
- تغيير `compileSdk` من القيمة التلقائية إلى `37` بشكل صريح.

#### [تنظيف] (Clean-up)
- تشغيل `flutter clean` و `flutter pub get`.
- التأكد من إيقاف أي عمليات Kotlin Daemon معلقة إذا لزم الأمر.

## خطة التحقق (Verification Plan)

### التحقق اليدوي
- تشغيل `flutter run` والتأكد من نجاح عملية البناء (Build Success).
- التأكد من اختفاء رسالة الخطأ الخاصة بـ `checkDebugAarMetadata`.
