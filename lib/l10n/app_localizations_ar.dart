// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'نوفا موديست';

  @override
  String get brandName => 'NOVA MODEST';

  @override
  String get splashTagline => 'احتشام عصري، يناسب كل يوم';

  @override
  String get onboardingTitle1 => 'تسوقي أناقتك بكل سهولة';

  @override
  String get onboardingBody1 =>
      'اكتشفي أحدث صيحات الموضة المحتشمة المختارة بعناية لتناسب ذوقك الرفيع.';

  @override
  String get onboardingTitle2 => 'تصاميم محتشمة بلمسة عصرية';

  @override
  String get onboardingBody2 =>
      'نجمع بين الأصالة والحداثة في قطع فريدة تعبر عن شخصيتك بأناقة تامة.';

  @override
  String get onboardingTitle3 => 'توصيل سريع وموثوق لباب بيتك';

  @override
  String get onboardingBody3 =>
      'نضمن لك تجربة تسوق آمنة وتوصيلاً سريعاً لجميع مشترياتك بكل عناية.';

  @override
  String get onboardingNext => 'التالي';

  @override
  String get onboardingStart => 'ابدأ';

  @override
  String get onboardingSkip => 'تخطي';

  @override
  String get authMethodTitle => 'تسجيل الدخول أو إنشاء حساب';

  @override
  String get authMethodSubtitle => 'تابعي طلباتك واحفظي عناوينك المفضلة';

  @override
  String get authContinueWithGoogle => 'المتابعة عبر Google';

  @override
  String get authOr => 'أو';

  @override
  String get authContinueWithEmail => 'متابعة بالبريد الإلكتروني';

  @override
  String get authContinueAsGuest => 'المتابعة كزائر';

  @override
  String get verifyEmailTitle => 'تحقق من بريدك الإلكتروني';

  @override
  String verifyEmailSubtitle(String email) {
    return 'أرسلنا رمزاً مكوناً من 6 أرقام إلى $email';
  }

  @override
  String get verifyEmailConfirm => 'تأكيد';

  @override
  String get verifyEmailResend => 'إعادة الإرسال';

  @override
  String get verifyEmailNoCode => 'لم يصلك الرمز؟';

  @override
  String get verifyEmailCodeIncomplete => 'أدخلي الرمز المكون من 6 أرقام';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navCategories => 'الفئات';

  @override
  String get navCart => 'السلة';

  @override
  String get navProfile => 'حسابي';

  @override
  String get homeHeroTagline => 'احتشام عصري، يناسب كل يوم';

  @override
  String get homeHeroCta => 'تسوقي الآن';

  @override
  String get homeCategoryAll => 'الكل';

  @override
  String get homeFeaturedTitle => 'منتجات مميزة';

  @override
  String get homeSeeAll => 'عرض الكل';

  @override
  String get homeEmpty => 'لا توجد منتجات بعد';

  @override
  String get homeFilterEmpty => 'لا توجد منتجات في هذه الفئة';

  @override
  String get homeSearch => 'بحث';

  @override
  String get currencySymbol => 'ر.س';

  @override
  String get productSoldOut => 'نفد من المخزن';

  @override
  String get productListFilter => 'تصفية';

  @override
  String get productListEmpty => 'لا توجد منتجات في هذه الفئة';

  @override
  String get productListFilterEmpty => 'لا توجد منتجات بهذا الفلتر';

  @override
  String get productColour => 'اللون';

  @override
  String get productSize => 'المقاس';

  @override
  String get productSizeGuide => 'دليل المقاسات';

  @override
  String get productDetails => 'التفاصيل';

  @override
  String get productAddToCart => 'أضيفي إلى السلة';

  @override
  String get productAddedToCart => 'تمت الإضافة إلى السلة';

  @override
  String get productDecreaseQuantity => 'إنقاص الكمية';

  @override
  String get productIncreaseQuantity => 'زيادة الكمية';

  @override
  String productImageCount(int current, int total) {
    return '$current من $total';
  }

  @override
  String get loginTitle => 'تسجيل الدخول';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get logoutButton => 'تسجيل الخروج';

  @override
  String get emailRequired => 'البريد الإلكتروني مطلوب';

  @override
  String get emailInvalid => 'أدخلي بريدًا إلكترونيًا صحيحًا';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get homeTitle => 'الرئيسية';

  @override
  String welcomeUser(String name) {
    return 'مرحبًا، $name';
  }

  @override
  String get failureNetwork => 'لا يوجد اتصال بالإنترنت.';

  @override
  String get failureServer => 'حدث خطأ في الخادم. يرجى المحاولة لاحقًا.';

  @override
  String get failureNotFound => 'لم يتم العثور على العنصر المطلوب.';

  @override
  String get failureUnauthorized =>
      'انتهت صلاحية الجلسة. يرجى تسجيل الدخول من جديد.';

  @override
  String get failureValidation => 'يرجى التحقق من البيانات المدخلة.';

  @override
  String get failureCache => 'البيانات المحلية غير متوفرة.';

  @override
  String get failureUnknown => 'حدث خطأ ما.';

  @override
  String get orderErrorSomeProduct => 'أحد منتجات سلتك';

  @override
  String orderErrorProductSoldOut(String product) {
    return '$product: نفدت الكمية. يرجى حذف المنتج من السلة لإتمام الطلب.';
  }

  @override
  String orderErrorProductNotFound(String product) {
    return '$product: لم يعد متوفراً في المتجر. يرجى حذف المنتج من السلة.';
  }

  @override
  String orderErrorColourNotForProduct(String product) {
    return '$product: اللون المختار لم يعد متاحاً. يرجى اختيار لون آخر.';
  }

  @override
  String orderErrorSizeNotForProduct(String product) {
    return '$product: المقاس المختار لم يعد متاحاً. يرجى اختيار مقاس آخر.';
  }

  @override
  String get orderErrorPaymentNotAvailable =>
      'الدفع بالبطاقة غير متاح حالياً. يرجى اختيار الدفع عند الاستلام.';

  @override
  String get orderErrorTooManyLines =>
      'لا يمكن إتمام طلب يحتوي أكثر من ٢٠ منتجاً مختلفاً. يرجى حذف بعض المنتجات من السلة.';

  @override
  String get orderErrorNotSignedIn =>
      'انتهت جلستك. يرجى تسجيل الدخول والمحاولة من جديد.';

  @override
  String get orderErrorTechnical =>
      'تعذّر إتمام الطلب بسبب خلل تقني لدينا. يرجى المحاولة مرة أخرى، وإذا تكرر تواصل معنا.';

  @override
  String get cartFull => 'سلتك ممتلئة. احذفي منتجاً لتضيفي غيره.';

  @override
  String get cartTitle => 'سلة التسوق';

  @override
  String cartVariant(String colour, String size) {
    return 'اللون: $colour | المقاس: $size';
  }

  @override
  String cartVariantColour(String colour) {
    return 'اللون: $colour';
  }

  @override
  String cartVariantSize(String size) {
    return 'المقاس: $size';
  }

  @override
  String get cartRemoveItem => 'إزالة من السلة';

  @override
  String get cartSubtotal => 'المجموع الفرعي';

  @override
  String get cartShipping => 'الشحن';

  @override
  String get cartTotal => 'الإجمالي';

  @override
  String get cartCheckout => 'متابعة الدفع';

  @override
  String get cartEmpty => 'سلتك فارغة';

  @override
  String get cartEmptyBody => 'أضيفي ما يعجبك من المنتجات وستجدينه هنا';

  @override
  String get cartEmptyCta => 'تسوّقي الآن';

  @override
  String get cartViewCart => 'عرض السلة';

  @override
  String get filterTitle => 'الفلاتر';

  @override
  String get filterClose => 'إغلاق';

  @override
  String get filterClearAll => 'مسح الكل';

  @override
  String get filterCategory => 'التصنيف';

  @override
  String get filterStyle => 'النمط';

  @override
  String get filterPriceRange => 'نطاق السعر';

  @override
  String filterPriceRangeValue(String min, String max) {
    return '$min - $max';
  }

  @override
  String get filterReset => 'إعادة تعيين';

  @override
  String filterApply(int count) {
    return 'عرض النتائج ($count)';
  }

  @override
  String get searchHint => 'ابحثي عما تفضلينه';

  @override
  String get searchClear => 'مسح البحث';

  @override
  String get searchRecent => 'عمليات بحث سابقة';

  @override
  String get searchRemoveTerm => 'إزالة من عمليات البحث السابقة';

  @override
  String get searchTrending => 'الأكثر بحثاً';

  @override
  String get searchExploreCategories => 'استكشفي الفئات';

  @override
  String searchResultCount(int count, String query) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نتيجة لـ «$query»',
      many: '$count نتيجة لـ «$query»',
      few: '$count نتائج لـ «$query»',
      two: 'نتيجتان لـ «$query»',
      one: 'نتيجة واحدة لـ «$query»',
      zero: 'لا نتائج لـ «$query»',
    );
    return '$_temp0';
  }

  @override
  String get searchSort => 'ترتيب';

  @override
  String get searchSortRelevance => 'الأكثر صلة';

  @override
  String get searchSortPriceAscending => 'السعر: من الأقل';

  @override
  String get searchSortPriceDescending => 'السعر: من الأعلى';

  @override
  String get searchEmptyTitle => 'لا توجد نتائج';

  @override
  String searchEmptyBody(String query) {
    return 'لم نجد شيئاً يطابق «$query». جرّبي كلمة أخرى.';
  }

  @override
  String get searchFilterEmpty => 'لا توجد نتائج بهذه الفلاتر';

  @override
  String get profileMyOrders => 'طلباتي';

  @override
  String get profilePersonalInfo => 'البيانات الشخصية';

  @override
  String get profileAddresses => 'العناوين';

  @override
  String get profileLanguage => 'اللغة';

  @override
  String get profileNotifications => 'الإشعارات';

  @override
  String get profileHelp => 'المساعدة والدعم';

  @override
  String get profileTerms => 'الشروط والأحكام';

  @override
  String get profileLogoutConfirm => 'هل تريدين تسجيل الخروج من حسابك؟';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get languageName => 'العربية';

  @override
  String get personalInfoSubtitle =>
      'حدّثي معلوماتك الشخصية للحفاظ على حسابك محدّثاً.';

  @override
  String get personalInfoFullName => 'الاسم الكامل';

  @override
  String get personalInfoEmailLocked => 'لا يمكن تغيير البريد الإلكتروني.';

  @override
  String get personalInfoPhone => 'رقم الجوال';

  @override
  String get personalInfoSave => 'حفظ التغييرات';

  @override
  String get personalInfoSaved => 'تم حفظ التغييرات';

  @override
  String get personalInfoNameRequired => 'الاسم مطلوب';

  @override
  String get personalInfoPhoneInvalid => 'أدخلي رقم جوال صحيح';

  @override
  String get personalInfoDiscardTitle => 'تعديلات غير محفوظة';

  @override
  String get personalInfoDiscardBody =>
      'لديك تعديلات لم تُحفظ. هل تريدين الخروج دون حفظها؟';

  @override
  String get personalInfoDiscard => 'خروج دون حفظ';

  @override
  String get addressListTitle => 'عناويني';

  @override
  String get addressDefaultBadge => 'الافتراضي';

  @override
  String get addressSetDefault => 'تعيين كافتراضي';

  @override
  String get addressEdit => 'تعديل العنوان';

  @override
  String get addressDelete => 'حذف العنوان';

  @override
  String get addressDeleteConfirm =>
      'سيُحذف هذا العنوان نهائيًا. هل تريدين المتابعة؟';

  @override
  String get addressAdd => 'إضافة عنوان جديد';

  @override
  String get addressEmpty => 'لا توجد عناوين محفوظة';

  @override
  String get addressEmptyBody => 'أضيفي عنوانًا ليصلك طلبك أسرع';

  @override
  String get addressLabelField => 'اسم العنوان';

  @override
  String get addressKind => 'النوع';

  @override
  String get addressKindHome => 'المنزل';

  @override
  String get addressKindWork => 'العمل';

  @override
  String get addressKindOther => 'أخرى';

  @override
  String get addressRecipient => 'اسم المستلم';

  @override
  String get addressCountry => 'الدولة';

  @override
  String get addressRegion => 'المنطقة';

  @override
  String get addressCity => 'المدينة';

  @override
  String get addressPostalCode => 'الرمز البريدي';

  @override
  String get addressStreet => 'العنوان بالتفصيل';

  @override
  String get addressStreetHint => 'اسم الشارع، رقم المبنى...';

  @override
  String get addressNotes => 'ملاحظات إضافية';

  @override
  String get addressNotesHint => 'علامة مميزة، وقت التوصيل المفضل...';

  @override
  String get addressMakeDefault => 'اجعله العنوان الافتراضي';

  @override
  String get addressSave => 'حفظ العنوان';

  @override
  String get addressSaved => 'تم حفظ العنوان';

  @override
  String get addressFieldRequired => 'هذا الحقل مطلوب';

  @override
  String get languageExplanation =>
      'سيتم تحديث لغة واجهة التطبيق فوراً بناءً على اختيارك.';

  @override
  String get languageNotSaved => 'تم تغيير اللغة، لكن تعذّر حفظ اختيارك.';

  @override
  String get helpFaqTitle => 'الأسئلة الشائعة';

  @override
  String get helpContactTitle => 'تواصلي معنا';

  @override
  String get helpFaqSignInQuestion => 'كيف أسجّل الدخول؟';

  @override
  String get helpFaqSignInAnswer =>
      'بحسابك في Google، أو برمز مكوّن من ٦ أرقام يصلك على بريدك الإلكتروني. لا توجد كلمة مرور في التطبيق.';

  @override
  String get helpFaqEmailQuestion => 'هل أستطيع تغيير بريدي الإلكتروني؟';

  @override
  String get helpFaqEmailAnswer =>
      'البريد مرتبط بحسابك ولا يمكن تغييره من التطبيق. أما الاسم ورقم الجوال فتعدّلينهما من «البيانات الشخصية».';

  @override
  String get helpFaqLanguageQuestion => 'كيف أغيّر لغة التطبيق؟';

  @override
  String get helpFaqLanguageAnswer =>
      'من «حسابي» ثم «اللغة». تتغيّر الواجهة فوراً دون إعادة تشغيل التطبيق.';

  @override
  String get helpFaqAddressQuestion => 'كيف أدير عناويني؟';

  @override
  String get helpFaqAddressAnswer =>
      'من «حسابي» ثم «العناوين». يمكنك الإضافة والتعديل والحذف، وتحديد عنوان واحد افتراضياً يصل إليه طلبك.';

  @override
  String get helpContactEmail => 'البريد الإلكتروني';

  @override
  String get helpCopy => 'نسخ';

  @override
  String get helpCopied => 'تم النسخ';

  @override
  String get termsBody =>
      '١. من نحن\nنوفا مودست متجرٌ إلكترونيٌّ للأزياء المحتشمة. لأي سؤال أو شكوى أو طلب، تواصلي معنا على: ezzdeenshamali@gmail.com\n\n٢. الأهلية\nالشراء من التطبيق متاحٌ لمن أتمّت الثامنة عشرة من عمرها.\n\n٣. حسابكِ\nيتم تسجيل الدخول برمزٍ يصل إلى بريدكِ الإلكتروني. لا توجد كلمة مرور، ولن نطلب منكِ واحدة.\nلا يمكن تغيير البريد الإلكتروني بعد إنشاء الحساب. أما الاسم ورقم الجوال والصورة الشخصية، فيمكنكِ تعديلها في أي وقت.\nالطلب يتطلّب تسجيل الدخول؛ لا يوجد شراءٌ كزائرة.\nأنتِ مسؤولةٌ عن صحّة ما تُدخلينه من اسمٍ ورقم جوالٍ وعنوان، فعليها يعتمد التوصيل.\nيمكنكِ حذف حسابكِ من صفحة «حسابي». يُحذف بذلك ملفكِ الشخصي وعناوينكِ المحفوظة وصورتكِ الشخصية نهائياً. أما طلباتكِ السابقة فتبقى لدى المتجر دون ربطٍ بحسابكِ، بما فيها نسخة الاسم والهاتف والعنوان المحفوظة مع كل طلب.\n\n٤. السلة والأسعار\nجميع الأسعار بالريال السعودي (ر.س).\nتتّسع السلة لعشرين صنفاً كحدٍّ أقصى، وعشر قطعٍ كحدٍّ أقصى من الصنف الواحد.\nالسعر المعتمد هو سعر المتجر لحظة إرسال الطلب، ويُحتسب لدينا لا على جهازكِ. فإن تغيّر السعر بين إضافة المنتج إلى السلة وإرسال الطلب، اعتُمد سعر لحظة الإرسال.\nبعد نجاح الطلب نحفظ نسخةً ثابتةً من أسماء المنتجات وأسعارها وكمياتها، فلا يغيّر أي تعديلٍ لاحقٍ على الكتالوج طلباً سابقاً.\n\n٥. التوصيل\nالتوصيل داخل المملكة العربية السعودية فقط.\nطريقةٌ واحدةٌ متاحة: التوصيل القياسي، ٣٥ ر.س، ومدّته المعروضة ٣-٥ أيام عمل.\nهذه المدّة تقديرٌ لا وعد، وتتأثر بالعنوان وبشركة التوصيل.\nيُسلَّم الطلب على العنوان الذي أدخلتِه، ولا يمكن تعديله من التطبيق بعد الإرسال.\n\n٦. الدفع\nالدفع عند الاستلام فقط، وعليه رسومٌ إضافيةٌ قدرها ١٥ ر.س، تظهر في السلة وفي صفحة مراجعة الطلب قبل الإرسال.\nالإجمالي = مجموع المنتجات + ٣٥ ر.س توصيل + ١٥ ر.س رسوم الدفع عند الاستلام.\nتُحصَّل هذه الرسوم مع مبلغ الطلب عند التسليم، فإن رُفض الاستلام لم يُدفع شيء.\nالدفع بالبطاقة غير متاحٍ حالياً ويظهر في التطبيق بوصف «قريباً». لا نجمع أي بيانات بطاقةٍ ولا نحفظها.\n\n٧. حالة الطلب\nيمرّ الطلب بخمس مراحل: قيد الانتظار، ثم مؤكّد، ثم قيد التحضير، ثم تم الشحن، ثم تم التوصيل.\n«مؤكّد» تعني أن المتجر قَبِل طلبكِ، ولا تعني أن المبلغ قد وصل، لأن الدفع يتم عند الاستلام.\nوهناك حالةٌ سادسة، ملغي، خارج هذا المسار.\n\n٨. الإلغاء\nلا يوجد زرّ إلغاءٍ داخل التطبيق؛ الإلغاء إجراءٌ يقوم به المتجر. إن رغبتِ في إلغاء طلبٍ فراسلينا على البريد أعلاه في أسرع وقتٍ ومعكِ رقم الطلب. ولا نضمن إمكانية الإلغاء بعد خروج الطلب للشحن.\nوللمتجر أن يلغي الطلب إذا نفد المنتج بعد إرسالكِ له، على أن نُشعركِ بذلك. ولا يترتّب عليكِ دفع شيء، لأن الدفع عند الاستلام.\n\n٩. الإرجاع والاستبدال\nيمكنكِ طلب الإرجاع خلال سبعة أيامٍ من استلام الطلب، للقطع غير المستعملة وبحالتها الأصلية، وذلك بالتواصل معنا عبر البريد الإلكتروني أعلاه.\n\n١٠. بياناتكِ\nنحفظ: بريدكِ الإلكتروني، واسمكِ، ورقم جوالكِ، وصورتكِ الشخصية إن رفعتِها، وعناوينكِ (الوصف، اسم المستلمة، الهاتف، الدولة، المنطقة، المدينة، الشارع، الرمز البريدي، الملاحظات).\nمع كل طلبٍ نحفظ نسخةً من اسم المستلمة وهاتفها وعنوان التوصيل، ليبقى الطلب مقروءاً حتى لو غيّرتِ عنوانكِ لاحقاً.\nالبيانات مخزّنةٌ لدى مزوّد الاستضافة Supabase.\nيطّلع فريق المتجر على طلباتكِ، بما فيها نسخة الاسم والهاتف والعنوان، لتنفيذها. أما ملفكِ الشخصي وعناوينكِ المحفوظة فلا يقرؤها أحدٌ سواكِ.\nصورتكِ الشخصية محفوظةٌ في مساحةٍ خاصة، وتُعرض عبر رابطٍ مؤقّتٍ صالحٍ لساعةٍ واحدة. ويمكن استبدالها، وتُحذف عند حذف حسابكِ.\nلا نبيع بياناتكِ ولا نشاركها لأغراض تسويق طرفٍ ثالث.\n\n١١. الإشعارات\nتحفظ شاشة الإشعارات تفضيلكِ، غير أن التطبيق لا يرسل إشعاراتٍ بعد. وعند تفعيلها يُطبَّق اختياركِ المحفوظ.\n\n١٢. القانون الحاكم\nتخضع هذه الشروط لأنظمة المملكة العربية السعودية.\n\n١٣. تعديل الشروط\nقد نُعدّل هذه الشروط، والنسخة المعروضة داخل التطبيق هي السارية.';

  @override
  String get notificationsOrders => 'إشعارات الطلبات';

  @override
  String get notificationsOrdersDescription =>
      'تأكيد الطلب وتحديثات الشحن والتوصيل.';

  @override
  String get notificationsPromotions => 'العروض والتخفيضات';

  @override
  String get notificationsPromotionsDescription =>
      'الحملات والتخفيضات ووصول القطع الجديدة.';

  @override
  String get notificationsDeviceNote =>
      'تحكّم إعدادات هاتفك في وصول الإشعارات أصلاً. إن كانت موقوفة هناك، فلن يصلك شيء مهما اخترت هنا.';

  @override
  String get notificationsNotLiveYet =>
      'الإشعارات غير مفعّلة بعد. اختيارك محفوظ وسيُطبَّق فور تفعيلها.';

  @override
  String get checkoutContactTitle => 'معلومات التواصل';

  @override
  String get checkoutAddressTitle => 'عنوان التوصيل';

  @override
  String get checkoutPaymentTitle => 'الشحن والدفع';

  @override
  String get checkoutReviewTitle => 'مراجعة الطلب';

  @override
  String get checkoutSuccessTitle => 'تم بنجاح';

  @override
  String get checkoutFullName => 'الاسم الكامل';

  @override
  String get checkoutFullNameHint => 'أدخلي اسمك الكامل';

  @override
  String get checkoutPhoneHint => '59 123 4567';

  @override
  String checkoutStepOf(int current, int total) {
    return 'الخطوة $current من $total';
  }

  @override
  String get checkoutSavedAddresses => 'العناوين المحفوظة';

  @override
  String get checkoutNewAddress => 'عنوان جديد';

  @override
  String get checkoutSaveAndContinue => 'حفظ ومتابعة';

  @override
  String get checkoutShippingMethod => 'طريقة الشحن';

  @override
  String get checkoutPaymentMethod => 'طريقة الدفع';

  @override
  String get checkoutShippingStandard => 'التوصيل القياسي';

  @override
  String get checkoutShippingStandardEta => '٣-٥ أيام عمل';

  @override
  String get checkoutPaymentCod => 'الدفع عند الاستلام';

  @override
  String checkoutPaymentCodFee(String fee) {
    return 'رسوم إضافية $fee';
  }

  @override
  String get checkoutPaymentCard => 'البطاقة الائتمانية';

  @override
  String get checkoutComingSoon => 'قريباً';

  @override
  String get checkoutPaymentFee => 'رسوم الدفع';

  @override
  String get checkoutOrderTotal => 'الإجمالي';

  @override
  String get checkoutToReview => 'مراجعة الطلب';

  @override
  String get reviewContactSection => 'معلومات الاتصال';

  @override
  String get reviewAddressSection => 'عنوان التوصيل';

  @override
  String get reviewShippingSection => 'طريقة الشحن';

  @override
  String get reviewPaymentSection => 'طريقة الدفع';

  @override
  String get reviewEdit => 'تعديل';

  @override
  String get reviewItems => 'المنتجات';

  @override
  String reviewQuantity(int count) {
    return 'الكمية: $count';
  }

  @override
  String get reviewPostalCode => 'الرمز البريدي:';

  @override
  String get reviewConfirm => 'تأكيد الطلب';

  @override
  String reviewShippingEta(String days) {
    return 'خلال $days';
  }

  @override
  String get successTitle => 'تم تأكيد طلبك بنجاح!';

  @override
  String get successOrderNumber => 'رقم الطلب:';

  @override
  String get successBody => 'سنتواصل معك قريبًا لتأكيد التوصيل.';

  @override
  String get successTrackOrder => 'تتبع الطلب';

  @override
  String get successKeepShopping => 'متابعة التسوق';

  @override
  String get ordersTitle => 'طلباتي';

  @override
  String ordersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count طلب',
      many: '$count طلبًا',
      few: '$count طلبات',
      two: 'طلبان',
      one: 'طلب واحد',
      zero: 'لا طلبات',
    );
    return '$_temp0';
  }

  @override
  String get ordersEmpty => 'لا توجد طلبات بعد';

  @override
  String get ordersEmptyBody => 'كل طلب تنهينه سيظهر هنا لتتابعيه';

  @override
  String get ordersEmptyAction => 'ابدئي التسوق';

  @override
  String ordersMoreItems(int count) {
    return '+$count';
  }

  @override
  String get orderStatusPending => 'قيد الانتظار';

  @override
  String get orderStatusConfirmed => 'مؤكد';

  @override
  String get orderStatusProcessing => 'قيد التحضير';

  @override
  String get orderStatusShipped => 'تم الشحن';

  @override
  String get orderStatusDelivered => 'مكتمل';

  @override
  String get orderStatusDeliveredLong => 'تم التوصيل';

  @override
  String get orderDetailTitle => 'تفاصيل الطلب';

  @override
  String orderPlacedOn(String date) {
    return 'تم الطلب في $date';
  }

  @override
  String orderNumberHeading(String number) {
    return 'الطلب #$number';
  }

  @override
  String get orderStatusHeading => 'حالة الطلب';

  @override
  String orderStatusCurrent(String status) {
    return 'حالة الطلب: $status';
  }

  @override
  String orderItemsHeading(int count) {
    return 'المنتجات ($count)';
  }

  @override
  String get orderDeliveryAddress => 'عنوان التوصيل';

  @override
  String get orderStatusCancelled => 'ملغي';

  @override
  String get profileAvatarChange => 'تغيير صورتك';

  @override
  String get profileAvatarUpdated => 'تم تحديث صورتك';

  @override
  String get avatarErrorFormat =>
      'هذه الصيغة غير مدعومة. اختاري صورة PNG أو JPEG أو WebP.';

  @override
  String get avatarErrorTooLarge => 'الصورة كبيرة جدًا. اختاري صورة أصغر.';

  @override
  String get accountDelete => 'حذف الحساب';

  @override
  String get accountDeleteBody =>
      'سيُحذف حسابكِ نهائياً، ومعه ملفكِ الشخصي وعناوينكِ المحفوظة وصورتكِ الشخصية، ولا يمكن التراجع عن ذلك.\n\nأما طلباتكِ السابقة فتبقى لدى المتجر دون ربطٍ بحسابكِ، بما فيها الاسم والهاتف والعنوان المسجّلة مع كل طلب.';

  @override
  String get accountDeleteErrorAdmin => 'حسابات الإدارة لا تُحذف من التطبيق.';

  @override
  String get accountDeleteErrorAvatar =>
      'تعذّر حذف صورتكِ الشخصية، فلم يُحذف شيء. أعيدي المحاولة لاحقاً.';

  @override
  String get accountDeleteErrorAccount =>
      'تعذّر حذف الحساب، وقد حُذفت صورتكِ الشخصية. أعيدي المحاولة لاحقاً.';

  @override
  String get accountDeleteErrorTechnical =>
      'تعذّر إتمام حذف الحساب لخلل تقني. أعيدي المحاولة لاحقاً.';
}
