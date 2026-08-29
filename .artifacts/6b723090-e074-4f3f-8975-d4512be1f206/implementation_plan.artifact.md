# خطة التصفير الشامل وإصلاح الذاكرة (الخيار الموصى به)

بناءً على المشاورات التقنية، سنقوم بإعادة المشروع إلى حالته الأصلية المتوافقة مع Flutter 3.44.8 مع حل مشكلة الذاكرة المقفولة.

## التغييرات المقترحة

### 1. إصلاح استهلاك الذاكرة (Trim JVM Args)
- **الملف**: `android/gradle.properties`
- **التعديل**: تغيير `org.gradle.jvmargs` من `-Xmx8G` إلى `-Xmx3G`.
- **إضافة**: `kotlin.daemon.jvmargs=-Xmx2G` لضمان استقرار محرك Kotlin.

### 2. استعادة أدوات البناء الأصلية (Revert Toolchain)
- **gradle-wrapper.properties**: العودة إلى `gradle-9.1.0-all.zip`.
- **settings.gradle.kts**: العودة إلى AGP `9.0.1` و Kotlin `2.3.20`.
- **build.gradle.kts (app)**: سنحاول العودة لـ `flutter.compileSdkVersion` (36)، وإذا فشل بسبب المكتبة، سنرفعه لـ 37 مع `compileSdkMinor = 0`.

### 3. التنظيف العميق (Deep Clean)
- تشغيل `flutter clean`.
- حذف مجلدات البناء يدوياً: `nova_modest/build` و `android/.gradle`.
- التأكد من حذف المجلد الخارجي إذا وجد (`../../build`).

## خطة التحقق
- تشغيل `flutter run`.
- مراقبة تحميل Gradle 9.1.0 (سيستغرق وقتاً لأن حجمه ~200MB).
- التأكد من نجاح الاتصال بالـ Daemon بعد تقليل الذاكرة.
