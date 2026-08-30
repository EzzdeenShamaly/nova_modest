import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// The application name, shown in the task switcher and app bars.
  ///
  /// In ar, this message translates to:
  /// **'نوفا موديست'**
  String get appTitle;

  /// The brand wordmark on the splash screen. DO NOT TRANSLATE and do not transliterate into Arabic letters - it is a fixed Latin brandmark in every locale. It lives in the ARB only so no user-facing literal sits in a widget.
  ///
  /// In ar, this message translates to:
  /// **'NOVA MODEST'**
  String get brandName;

  /// Tagline under the brand wordmark on the splash screen. Short - it must fit one line at 14sp on a 375pt-wide screen.
  ///
  /// In ar, this message translates to:
  /// **'احتشام عصري، يناسب كل يوم'**
  String get splashTagline;

  /// Onboarding slide 1 title - shopping ease. Short: one line at 24sp on a 375pt screen.
  ///
  /// In ar, this message translates to:
  /// **'تسوقي أناقتك بكل سهولة'**
  String get onboardingTitle1;

  /// Onboarding slide 1 body. Two to three lines at 16sp. No hard line breaks - it must wrap to the device width.
  ///
  /// In ar, this message translates to:
  /// **'اكتشفي أحدث صيحات الموضة المحتشمة المختارة بعناية لتناسب ذوقك الرفيع.'**
  String get onboardingBody1;

  /// Onboarding slide 2 title - modest, modern designs. Short: one line at 24sp on a 375pt screen.
  ///
  /// In ar, this message translates to:
  /// **'تصاميم محتشمة بلمسة عصرية'**
  String get onboardingTitle2;

  /// Onboarding slide 2 body. Two to three lines at 16sp. No hard line breaks - it must wrap to the device width.
  ///
  /// In ar, this message translates to:
  /// **'نجمع بين الأصالة والحداثة في قطع فريدة تعبر عن شخصيتك بأناقة تامة.'**
  String get onboardingBody2;

  /// Onboarding slide 3 title - fast delivery. Short: one line at 24sp on a 375pt screen.
  ///
  /// In ar, this message translates to:
  /// **'توصيل سريع وموثوق لباب بيتك'**
  String get onboardingTitle3;

  /// Onboarding slide 3 body. Two to three lines at 16sp. No hard line breaks - it must wrap to the device width.
  ///
  /// In ar, this message translates to:
  /// **'نضمن لك تجربة تسوق آمنة وتوصيلاً سريعاً لجميع مشترياتك بكل عناية.'**
  String get onboardingBody3;

  /// Advances to the next onboarding slide. Shown on slides 1 and 2.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get onboardingNext;

  /// Finishes the onboarding and enters the app. Shown on the last slide only.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ'**
  String get onboardingStart;

  /// Dismisses the onboarding entirely. Same effect as finishing it.
  ///
  /// In ar, this message translates to:
  /// **'تخطي'**
  String get onboardingSkip;

  /// Heading on the sign-in method screen. Covers both signing in and creating an account - the flow does not distinguish them.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول أو إنشاء حساب'**
  String get authMethodTitle;

  /// Supporting line under the sign-in heading, explaining why signing in is worth it.
  ///
  /// In ar, this message translates to:
  /// **'تابعي طلباتك واحفظي عناوينك المفضلة'**
  String get authMethodSubtitle;

  /// Label of the Google sign-in button. "Google" is a brand name and stays Latin in every locale.
  ///
  /// In ar, this message translates to:
  /// **'المتابعة عبر Google'**
  String get authContinueWithGoogle;

  /// Separator between the Google button and the email form. One word.
  ///
  /// In ar, this message translates to:
  /// **'أو'**
  String get authOr;

  /// Submits the email address and requests a one-time code.
  ///
  /// In ar, this message translates to:
  /// **'متابعة بالبريد الإلكتروني'**
  String get authContinueWithEmail;

  /// Skips signing in. Browsing is public, so this simply returns to Home.
  ///
  /// In ar, this message translates to:
  /// **'المتابعة كزائر'**
  String get authContinueAsGuest;

  /// Heading on the code-verification screen.
  ///
  /// In ar, this message translates to:
  /// **'تحقق من بريدك الإلكتروني'**
  String get verifyEmailTitle;

  /// Tells the user where the six-digit code was sent.
  ///
  /// In ar, this message translates to:
  /// **'أرسلنا رمزاً مكوناً من 6 أرقام إلى {email}'**
  String verifyEmailSubtitle(String email);

  /// Submits the entered code.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get verifyEmailConfirm;

  /// Requests a new code. Disabled until the countdown reaches zero.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الإرسال'**
  String get verifyEmailResend;

  /// Precedes the resend action: "did not get the code?"
  ///
  /// In ar, this message translates to:
  /// **'لم يصلك الرمز؟'**
  String get verifyEmailNoCode;

  /// Validation shown when fewer than six digits were entered.
  ///
  /// In ar, this message translates to:
  /// **'أدخلي الرمز المكون من 6 أرقام'**
  String get verifyEmailCodeIncomplete;

  /// Bottom navigation label for the home tab.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get navHome;

  /// Bottom navigation label for the categories tab.
  ///
  /// In ar, this message translates to:
  /// **'الفئات'**
  String get navCategories;

  /// Bottom navigation label for the cart tab.
  ///
  /// In ar, this message translates to:
  /// **'السلة'**
  String get navCart;

  /// Bottom navigation label for the account tab.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get navProfile;

  /// Tagline over the hero banner on Home. Same wording as the splash tagline, by design.
  ///
  /// In ar, this message translates to:
  /// **'احتشام عصري، يناسب كل يوم'**
  String get homeHeroTagline;

  /// Button on the hero banner that opens the catalogue.
  ///
  /// In ar, this message translates to:
  /// **'تسوقي الآن'**
  String get homeHeroCta;

  /// First filter chip, clearing any category filter. A UI affordance, not a category the backend returns.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get homeCategoryAll;

  /// Heading of the featured products grid.
  ///
  /// In ar, this message translates to:
  /// **'منتجات مميزة'**
  String get homeFeaturedTitle;

  /// Link beside the featured heading that opens the full catalogue.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل'**
  String get homeSeeAll;

  /// Shown when the catalogue itself is empty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد منتجات بعد'**
  String get homeEmpty;

  /// Shown inside the grid when the chosen category has nothing in it. The chips stay visible so another can be picked.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد منتجات في هذه الفئة'**
  String get homeFilterEmpty;

  /// Screen-reader label for the heart button on a product card.
  ///
  /// In ar, this message translates to:
  /// **'إضافة للمفضلة'**
  String get homeFavourite;

  /// Screen-reader label for the search action in the Home app bar.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get homeSearch;

  /// Currency symbol shown after a price. Saudi riyal.
  ///
  /// In ar, this message translates to:
  /// **'ر.س'**
  String get currencySymbol;

  /// Badge on a product card whose stock has run out.
  ///
  /// In ar, this message translates to:
  /// **'نفد من المخزن'**
  String get productSoldOut;

  /// Screen-reader label for the filter control in the product listing app bar.
  ///
  /// In ar, this message translates to:
  /// **'تصفية'**
  String get productListFilter;

  /// Shown when the category itself holds no products.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد منتجات في هذه الفئة'**
  String get productListEmpty;

  /// Shown inside the grid when the chosen tag matches nothing. The chips stay visible so another can be picked.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد منتجات بهذا الفلتر'**
  String get productListFilterEmpty;

  /// Heading of the colour selector on a product page.
  ///
  /// In ar, this message translates to:
  /// **'اللون'**
  String get productColour;

  /// Heading of the size selector on a product page.
  ///
  /// In ar, this message translates to:
  /// **'المقاس'**
  String get productSize;

  /// Link to the sizing chart. The chart screen is not built yet.
  ///
  /// In ar, this message translates to:
  /// **'دليل المقاسات'**
  String get productSizeGuide;

  /// Heading of the description section on a product page.
  ///
  /// In ar, this message translates to:
  /// **'التفاصيل'**
  String get productDetails;

  /// Primary action on a product page.
  ///
  /// In ar, this message translates to:
  /// **'أضف إلى السلة'**
  String get productAddToCart;

  /// Confirmation shown after adding a product. The cart screen itself is not built yet.
  ///
  /// In ar, this message translates to:
  /// **'تمت الإضافة إلى السلة'**
  String get productAddedToCart;

  /// Screen-reader label for the share action on a product page.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get productShare;

  /// Screen-reader label for the minus button on the quantity stepper.
  ///
  /// In ar, this message translates to:
  /// **'إنقاص الكمية'**
  String get productDecreaseQuantity;

  /// Screen-reader label for the plus button on the quantity stepper.
  ///
  /// In ar, this message translates to:
  /// **'زيادة الكمية'**
  String get productIncreaseQuantity;

  /// Screen-reader position within the product image carousel.
  ///
  /// In ar, this message translates to:
  /// **'{current} من {total}'**
  String productImageCount(int current, int total);

  /// Title of the login screen.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get loginTitle;

  /// Label for the email text field on the login form.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get emailLabel;

  /// Label of the sign-out action.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get logoutButton;

  /// Validation message shown when the email field is empty.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني مطلوب'**
  String get emailRequired;

  /// Validation message shown when the email field is not a valid address.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بريدًا إلكترونيًا صحيحًا'**
  String get emailInvalid;

  /// Label of the retry action on an error state.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// Title of the home screen shown after a successful sign-in.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get homeTitle;

  /// Greeting shown on the home screen after sign-in.
  ///
  /// In ar, this message translates to:
  /// **'مرحبًا، {name}'**
  String welcomeUser(String name);

  /// Shown for NetworkFailure — no connectivity or a timeout.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت.'**
  String get failureNetwork;

  /// Shown for ServerFailure — a 5xx response.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ في الخادم. يرجى المحاولة لاحقًا.'**
  String get failureServer;

  /// Shown for NotFoundFailure — a 404 response.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على العنصر المطلوب.'**
  String get failureNotFound;

  /// Shown for UnauthorizedFailure — a 401 or 403 response.
  ///
  /// In ar, this message translates to:
  /// **'انتهت صلاحية الجلسة. يرجى تسجيل الدخول من جديد.'**
  String get failureUnauthorized;

  /// Shown for ValidationFailure — a 422 response.
  ///
  /// In ar, this message translates to:
  /// **'يرجى التحقق من البيانات المدخلة.'**
  String get failureValidation;

  /// Shown for CacheFailure — local data could not be read.
  ///
  /// In ar, this message translates to:
  /// **'البيانات المحلية غير متوفرة.'**
  String get failureCache;

  /// Shown for UnknownFailure — an unclassified error.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ ما.'**
  String get failureUnknown;

  /// Heading of the cart screen. Also the bottom-navigation destination it belongs to.
  ///
  /// In ar, this message translates to:
  /// **'سلة التسوق'**
  String get cartTitle;

  /// The choices made on one cart line, shown under the product name. Composed as one string rather than joining translated fragments in code, so a translator controls the separator and the word order.
  ///
  /// In ar, this message translates to:
  /// **'اللون: {colour} | المقاس: {size}'**
  String cartVariant(String colour, String size);

  /// Same line as cartVariant for a product that offers no sizes.
  ///
  /// In ar, this message translates to:
  /// **'اللون: {colour}'**
  String cartVariantColour(String colour);

  /// Same line as cartVariant for a product that offers no colours.
  ///
  /// In ar, this message translates to:
  /// **'المقاس: {size}'**
  String cartVariantSize(String size);

  /// Screen-reader label and tooltip for the × on a cart line.
  ///
  /// In ar, this message translates to:
  /// **'إزالة من السلة'**
  String get cartRemoveItem;

  /// Summary row: the sum of the line totals, before shipping.
  ///
  /// In ar, this message translates to:
  /// **'المجموع الفرعي'**
  String get cartSubtotal;

  /// Summary row: the delivery fee.
  ///
  /// In ar, this message translates to:
  /// **'الشحن'**
  String get cartShipping;

  /// Summary row: subtotal plus shipping. The emphasised row.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get cartTotal;

  /// Primary action in the cart's sticky bar. Disabled until the checkout screen exists.
  ///
  /// In ar, this message translates to:
  /// **'متابعة الدفع'**
  String get cartCheckout;

  /// Heading shown when the cart holds nothing.
  ///
  /// In ar, this message translates to:
  /// **'سلتك فارغة'**
  String get cartEmpty;

  /// Supporting line under the empty-cart heading. Two lines at most at 14sp on a 375pt screen.
  ///
  /// In ar, this message translates to:
  /// **'أضيفي ما يعجبك من المنتجات وستجدينه هنا'**
  String get cartEmptyBody;

  /// Button on the empty cart that returns to the catalogue.
  ///
  /// In ar, this message translates to:
  /// **'تسوّقي الآن'**
  String get cartEmptyCta;

  /// Action on the confirmation shown after adding a product, opening the cart tab.
  ///
  /// In ar, this message translates to:
  /// **'عرض السلة'**
  String get cartViewCart;

  /// Heading of the shared filter sheet, used by the product listing and by search results.
  ///
  /// In ar, this message translates to:
  /// **'الفلاتر'**
  String get filterTitle;

  /// Screen-reader label for the sheet's close control.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get filterClose;

  /// Clears every facet at once, from the sheet header.
  ///
  /// In ar, this message translates to:
  /// **'مسح الكل'**
  String get filterClearAll;

  /// Facet heading: which catalogue category a product belongs to.
  ///
  /// In ar, this message translates to:
  /// **'التصنيف'**
  String get filterCategory;

  /// Facet heading for the product tags (everyday, occasion, colourful). Distinct from cartVariant's category: a tag describes the style, not the section of the catalogue.
  ///
  /// In ar, this message translates to:
  /// **'النمط'**
  String get filterStyle;

  /// Facet heading for the price slider.
  ///
  /// In ar, this message translates to:
  /// **'نطاق السعر'**
  String get filterPriceRange;

  /// The currently selected price bounds, shown beside the price heading. Both values arrive already formatted with the currency symbol, so this entry controls only the separator and the order.
  ///
  /// In ar, this message translates to:
  /// **'{min} - {max}'**
  String filterPriceRangeValue(String min, String max);

  /// Secondary action in the sheet footer: clears the facets without closing.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تعيين'**
  String get filterReset;

  /// Primary action in the sheet footer. The number is how many products the pending filter matches, so the shopper sees the effect before applying it.
  ///
  /// In ar, this message translates to:
  /// **'عرض النتائج ({count})'**
  String filterApply(int count);

  /// Placeholder inside the search field. Fits one line at 16sp on a 375pt screen.
  ///
  /// In ar, this message translates to:
  /// **'ابحثي عما تفضلينه'**
  String get searchHint;

  /// Screen-reader label for the clear control inside the search field.
  ///
  /// In ar, this message translates to:
  /// **'مسح البحث'**
  String get searchClear;

  /// Heading of the recent-searches section on the search screen.
  ///
  /// In ar, this message translates to:
  /// **'عمليات بحث سابقة'**
  String get searchRecent;

  /// Screen-reader label for the small close control on one recent-search chip.
  ///
  /// In ar, this message translates to:
  /// **'إزالة من عمليات البحث السابقة'**
  String get searchRemoveTerm;

  /// Heading of the suggested search terms the catalogue offers.
  ///
  /// In ar, this message translates to:
  /// **'الأكثر بحثاً'**
  String get searchTrending;

  /// Heading of the category cards offered instead of searching.
  ///
  /// In ar, this message translates to:
  /// **'استكشفي الفئات'**
  String get searchExploreCategories;

  /// Heading above the results grid, stating how many products matched. ICU plural: Arabic has six forms and a ternary would be wrong in most of them.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{لا نتائج لـ «{query}»} =1{نتيجة واحدة لـ «{query}»} =2{نتيجتان لـ «{query}»} few{{count} نتائج لـ «{query}»} many{{count} نتيجة لـ «{query}»} other{{count} نتيجة لـ «{query}»}}'**
  String searchResultCount(int count, String query);

  /// Opens the ordering options above the results grid.
  ///
  /// In ar, this message translates to:
  /// **'ترتيب'**
  String get searchSort;

  /// Ordering option: the catalogue's own order for the query.
  ///
  /// In ar, this message translates to:
  /// **'الأكثر صلة'**
  String get searchSortRelevance;

  /// Ordering option: cheapest first.
  ///
  /// In ar, this message translates to:
  /// **'السعر: من الأقل'**
  String get searchSortPriceAscending;

  /// Ordering option: most expensive first.
  ///
  /// In ar, this message translates to:
  /// **'السعر: من الأعلى'**
  String get searchSortPriceDescending;

  /// Heading shown when a query matched nothing in the catalogue.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج'**
  String get searchEmptyTitle;

  /// Supporting line under the no-results heading, repeating what was searched for.
  ///
  /// In ar, this message translates to:
  /// **'لم نجد شيئاً يطابق «{query}». جرّبي كلمة أخرى.'**
  String searchEmptyBody(String query);

  /// Shown inside the grid when the chosen filters cover nothing, while the query itself matched something. The filter controls stay visible so they can be widened.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج بهذه الفلاتر'**
  String get searchFilterEmpty;

  /// Account menu row leading to the shopper's past orders.
  ///
  /// In ar, this message translates to:
  /// **'طلباتي'**
  String get profileMyOrders;

  /// Account menu row leading to the name/email/phone editor.
  ///
  /// In ar, this message translates to:
  /// **'البيانات الشخصية'**
  String get profilePersonalInfo;

  /// Account menu row leading to the saved delivery addresses.
  ///
  /// In ar, this message translates to:
  /// **'العناوين'**
  String get profileAddresses;

  /// Account menu row leading to the language chooser. Shows the current language as its value.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get profileLanguage;

  /// Account menu row leading to the notification preferences.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get profileNotifications;

  /// Account menu row leading to help and customer support.
  ///
  /// In ar, this message translates to:
  /// **'المساعدة والدعم'**
  String get profileHelp;

  /// Account menu row leading to the terms and conditions.
  ///
  /// In ar, this message translates to:
  /// **'الشروط والأحكام'**
  String get profileTerms;

  /// Body of the confirmation asked before signing out. Ending the session with one stray tap inside a scrolling list is the easiest mistake on this screen.
  ///
  /// In ar, this message translates to:
  /// **'هل تريدين تسجيل الخروج من حسابك؟'**
  String get profileLogoutConfirm;

  /// Dismisses a confirmation without acting. Generic, reused by any dialog.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get commonCancel;

  /// The name of THIS locale, written in it. Each locale names itself, so the account screen can show the current language without a lookup table. DO NOT translate - render the language's own endonym.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get languageName;

  /// Supporting line under the personal-information heading. Two lines at most at 16sp on a 375pt screen.
  ///
  /// In ar, this message translates to:
  /// **'قم بتحديث معلوماتك الشخصية للحفاظ على حسابك محدثاً.'**
  String get personalInfoSubtitle;

  /// Label of the editable name field.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get personalInfoFullName;

  /// Note under the disabled email field. The address is fixed for the account, not merely disabled in this screen.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن تغيير البريد الإلكتروني.'**
  String get personalInfoEmailLocked;

  /// Label of the editable phone field. Optional - an account created with Google may have no number.
  ///
  /// In ar, this message translates to:
  /// **'رقم الجوال'**
  String get personalInfoPhone;

  /// Primary action in the sticky bar.
  ///
  /// In ar, this message translates to:
  /// **'حفظ التغييرات'**
  String get personalInfoSave;

  /// Confirmation shown after the profile is saved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ التغييرات'**
  String get personalInfoSaved;

  /// Validation shown when the name field is left empty.
  ///
  /// In ar, this message translates to:
  /// **'الاسم مطلوب'**
  String get personalInfoNameRequired;

  /// Validation shown when the phone field holds something that is not a number. Deliberately loose - no country format is specified.
  ///
  /// In ar, this message translates to:
  /// **'أدخلي رقم جوال صحيح'**
  String get personalInfoPhoneInvalid;

  /// Heading of the confirmation asked when leaving with unsaved edits.
  ///
  /// In ar, this message translates to:
  /// **'تعديلات غير محفوظة'**
  String get personalInfoDiscardTitle;

  /// Body of the unsaved-changes confirmation.
  ///
  /// In ar, this message translates to:
  /// **'لديك تعديلات لم تُحفظ. هل تريدين الخروج دون حفظها؟'**
  String get personalInfoDiscardBody;

  /// Confirming action of the unsaved-changes dialog: leave and lose the edits.
  ///
  /// In ar, this message translates to:
  /// **'خروج دون حفظ'**
  String get personalInfoDiscard;

  /// Heading of the saved-addresses screen.
  ///
  /// In ar, this message translates to:
  /// **'عناويني'**
  String get addressListTitle;

  /// Badge on the address that orders default to.
  ///
  /// In ar, this message translates to:
  /// **'الافتراضي'**
  String get addressDefaultBadge;

  /// Action making one address the default. Only offered on the ones that are not.
  ///
  /// In ar, this message translates to:
  /// **'تعيين كافتراضي'**
  String get addressSetDefault;

  /// Screen-reader label and tooltip for the edit control on an address card. Also the heading when editing.
  ///
  /// In ar, this message translates to:
  /// **'تعديل العنوان'**
  String get addressEdit;

  /// Screen-reader label for the delete control, and the heading of its confirmation.
  ///
  /// In ar, this message translates to:
  /// **'حذف العنوان'**
  String get addressDelete;

  /// Body of the delete confirmation.
  ///
  /// In ar, this message translates to:
  /// **'سيُحذف هذا العنوان نهائيًا. هل تريدين المتابعة؟'**
  String get addressDeleteConfirm;

  /// Primary action on the addresses screen, and the heading when adding.
  ///
  /// In ar, this message translates to:
  /// **'إضافة عنوان جديد'**
  String get addressAdd;

  /// Heading shown when nothing has been saved yet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عناوين محفوظة'**
  String get addressEmpty;

  /// Supporting line under the empty-addresses heading.
  ///
  /// In ar, this message translates to:
  /// **'أضيفي عنوانًا ليصلك طلبك أسرع'**
  String get addressEmptyBody;

  /// Label of the free-text field naming an address - the shopper may call it anything.
  ///
  /// In ar, this message translates to:
  /// **'اسم العنوان'**
  String get addressLabelField;

  /// Label of the home/work/other selector, which picks the card's icon.
  ///
  /// In ar, this message translates to:
  /// **'النوع'**
  String get addressKind;

  /// Address type: a home. Also the default name suggested for one.
  ///
  /// In ar, this message translates to:
  /// **'المنزل'**
  String get addressKindHome;

  /// Address type: a workplace.
  ///
  /// In ar, this message translates to:
  /// **'العمل'**
  String get addressKindWork;

  /// Address type: anything else.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get addressKindOther;

  /// Label of the recipient field - who receives the parcel, not necessarily the account holder.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستلم'**
  String get addressRecipient;

  /// Label of the country selector.
  ///
  /// In ar, this message translates to:
  /// **'الدولة'**
  String get addressCountry;

  /// Label of the district field. The design's example is a neighbourhood, not a province.
  ///
  /// In ar, this message translates to:
  /// **'المنطقة'**
  String get addressRegion;

  /// Label of the city field.
  ///
  /// In ar, this message translates to:
  /// **'المدينة'**
  String get addressCity;

  /// Label of the optional postal code field.
  ///
  /// In ar, this message translates to:
  /// **'الرمز البريدي'**
  String get addressPostalCode;

  /// Label of the multi-line street field.
  ///
  /// In ar, this message translates to:
  /// **'العنوان بالتفصيل'**
  String get addressStreet;

  /// Placeholder inside the street field.
  ///
  /// In ar, this message translates to:
  /// **'اسم الشارع، رقم المبنى...'**
  String get addressStreetHint;

  /// Label of the optional notes field - read by whoever delivers, shown on no card.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات إضافية'**
  String get addressNotes;

  /// Placeholder inside the notes field.
  ///
  /// In ar, this message translates to:
  /// **'علامة مميزة، وقت التوصيل المفضل...'**
  String get addressNotesHint;

  /// Switch in the form making the saved address the default one.
  ///
  /// In ar, this message translates to:
  /// **'اجعله العنوان الافتراضي'**
  String get addressMakeDefault;

  /// Primary action of the address form.
  ///
  /// In ar, this message translates to:
  /// **'حفظ العنوان'**
  String get addressSave;

  /// Confirmation shown after an address is saved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ العنوان'**
  String get addressSaved;

  /// Validation shown when a required address field is left empty.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحقل مطلوب'**
  String get addressFieldRequired;

  /// Line under the language options. It promises an immediate switch with no restart, which is the behaviour the screen actually implements.
  ///
  /// In ar, this message translates to:
  /// **'سيتم تحديث لغة واجهة التطبيق فوراً بناءً على اختيارك.'**
  String get languageExplanation;

  /// Shown when the language was applied but could not be written to storage - so the shopper knows it will not survive a restart.
  ///
  /// In ar, this message translates to:
  /// **'تم تغيير اللغة، لكن تعذّر حفظ اختيارك.'**
  String get languageNotSaved;

  /// Heading of the FAQ section on the help screen.
  ///
  /// In ar, this message translates to:
  /// **'الأسئلة الشائعة'**
  String get helpFaqTitle;

  /// Heading of the contact section on the help screen.
  ///
  /// In ar, this message translates to:
  /// **'تواصلي معنا'**
  String get helpContactTitle;

  /// FAQ question about signing in.
  ///
  /// In ar, this message translates to:
  /// **'كيف أسجّل الدخول؟'**
  String get helpFaqSignInQuestion;

  /// FAQ answer describing the passwordless sign-in the app actually implements.
  ///
  /// In ar, this message translates to:
  /// **'بحسابك في Google، أو برمز مكوّن من ٦ أرقام يصلك على بريدك الإلكتروني. لا توجد كلمة مرور في التطبيق.'**
  String get helpFaqSignInAnswer;

  /// FAQ question about changing the account email.
  ///
  /// In ar, this message translates to:
  /// **'هل أستطيع تغيير بريدي الإلكتروني؟'**
  String get helpFaqEmailQuestion;

  /// FAQ answer. The email really is unchangeable - the update contract has no field for it.
  ///
  /// In ar, this message translates to:
  /// **'البريد مرتبط بحسابك ولا يمكن تغييره من التطبيق. أما الاسم ورقم الجوال فتعدّلينهما من «البيانات الشخصية».'**
  String get helpFaqEmailAnswer;

  /// FAQ question about switching language.
  ///
  /// In ar, this message translates to:
  /// **'كيف أغيّر لغة التطبيق؟'**
  String get helpFaqLanguageQuestion;

  /// FAQ answer describing the language screen's actual behaviour.
  ///
  /// In ar, this message translates to:
  /// **'من «حسابي» ثم «اللغة». تتغيّر الواجهة فوراً دون إعادة تشغيل التطبيق.'**
  String get helpFaqLanguageAnswer;

  /// FAQ question about managing addresses.
  ///
  /// In ar, this message translates to:
  /// **'كيف أدير عناويني؟'**
  String get helpFaqAddressQuestion;

  /// FAQ answer describing the addresses screen, including the one-default rule.
  ///
  /// In ar, this message translates to:
  /// **'من «حسابي» ثم «العناوين». يمكنك الإضافة والتعديل والحذف، وتحديد عنوان واحد افتراضياً يصل إليه طلبك.'**
  String get helpFaqAddressAnswer;

  /// Label of the support email row.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get helpContactEmail;

  /// Label of the support phone row.
  ///
  /// In ar, this message translates to:
  /// **'هاتف الدعم'**
  String get helpContactPhone;

  /// Screen-reader label and tooltip for the copy control on a contact row.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get helpCopy;

  /// Confirmation shown after a contact detail is copied to the clipboard.
  ///
  /// In ar, this message translates to:
  /// **'تم النسخ'**
  String get helpCopied;

  /// The stand-in shown until the real terms text is supplied. Deliberately not draft legal wording - policy is a business decision, not a technical one.
  ///
  /// In ar, this message translates to:
  /// **'سيتم إضافة الشروط والأحكام الكاملة هنا.'**
  String get termsPlaceholder;

  /// Second line under the terms placeholder, telling the reader the absence is known rather than broken.
  ///
  /// In ar, this message translates to:
  /// **'النسخة النهائية قيد الإعداد. للاستفسار، تواصلي معنا من «المساعدة والدعم».'**
  String get termsPlaceholderNote;

  /// Title of the transactional notifications preference.
  ///
  /// In ar, this message translates to:
  /// **'إشعارات الطلبات'**
  String get notificationsOrders;

  /// What the orders preference actually covers. Transactional, which is why it is on by default.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الطلب وتحديثات الشحن والتوصيل.'**
  String get notificationsOrdersDescription;

  /// Title of the promotional notifications preference.
  ///
  /// In ar, this message translates to:
  /// **'العروض والتخفيضات'**
  String get notificationsPromotions;

  /// What the promotions preference covers. Marketing, which is why it is off by default.
  ///
  /// In ar, this message translates to:
  /// **'الحملات والتخفيضات ووصول القطع الجديدة.'**
  String get notificationsPromotionsDescription;

  /// Note under the switches. The app cannot read the OS permission - no permission package is a dependency - so it says so plainly rather than letting the switches imply a guarantee they cannot make.
  ///
  /// In ar, this message translates to:
  /// **'تحكّم إعدادات هاتفك في وصول الإشعارات أصلاً. إن كانت موقوفة هناك، فلن يصلك شيء مهما اخترت هنا.'**
  String get notificationsDeviceNote;

  /// App-bar title for checkout step 1.
  ///
  /// In ar, this message translates to:
  /// **'معلومات التواصل'**
  String get checkoutContactTitle;

  /// App-bar title for checkout step 2.
  ///
  /// In ar, this message translates to:
  /// **'عنوان التوصيل'**
  String get checkoutAddressTitle;

  /// App-bar title for checkout step 3.
  ///
  /// In ar, this message translates to:
  /// **'الشحن والدفع'**
  String get checkoutPaymentTitle;

  /// App-bar title for the confirmation screen after the three steps.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة الطلب'**
  String get checkoutReviewTitle;

  /// App-bar title for the order-placed screen.
  ///
  /// In ar, this message translates to:
  /// **'تم بنجاح'**
  String get checkoutSuccessTitle;

  /// Label of the name field in checkout step 1. Separate from personalInfoFullName because this one names the order's recipient, not the account holder - a shopper may buy for someone else.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get checkoutFullName;

  /// Placeholder inside the checkout name field.
  ///
  /// In ar, this message translates to:
  /// **'أدخل اسمك الكامل'**
  String get checkoutFullNameHint;

  /// Placeholder inside the checkout phone field, shown after the dialling code. Digits only - the code is its own control.
  ///
  /// In ar, this message translates to:
  /// **'59 123 4567'**
  String get checkoutPhoneHint;

  /// Screen-reader label for the step indicator, which is dots only and says nothing to a screen reader on its own.
  ///
  /// In ar, this message translates to:
  /// **'الخطوة {current} من {total}'**
  String checkoutStepOf(int current, int total);

  /// Heading over the saved-address cards in checkout step 2.
  ///
  /// In ar, this message translates to:
  /// **'العناوين المحفوظة'**
  String get checkoutSavedAddresses;

  /// Heading of the inline address form in checkout step 2. Distinct from addressAdd, which is the button that opens it.
  ///
  /// In ar, this message translates to:
  /// **'عنوان جديد'**
  String get checkoutNewAddress;

  /// Primary action of checkout step 2 - it saves the address as well as advancing, which the generic Next does not say.
  ///
  /// In ar, this message translates to:
  /// **'حفظ ومتابعة'**
  String get checkoutSaveAndContinue;

  /// Heading over the shipping options in checkout step 3.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الشحن'**
  String get checkoutShippingMethod;

  /// Heading over the payment options in checkout step 3.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الدفع'**
  String get checkoutPaymentMethod;

  /// Name of the one shipping method the shop offers.
  ///
  /// In ar, this message translates to:
  /// **'التوصيل القياسي'**
  String get checkoutShippingStandard;

  /// Delivery window under the standard shipping method.
  ///
  /// In ar, this message translates to:
  /// **'٣-٥ أيام عمل'**
  String get checkoutShippingStandardEta;

  /// Name of the cash-on-delivery payment method.
  ///
  /// In ar, this message translates to:
  /// **'الدفع عند الاستلام'**
  String get checkoutPaymentCod;

  /// Surcharge line under cash on delivery. The amount is formatted as currency by the caller.
  ///
  /// In ar, this message translates to:
  /// **'رسوم إضافية {fee}'**
  String checkoutPaymentCodFee(String fee);

  /// Name of the card payment method, which is drawn but not selectable.
  ///
  /// In ar, this message translates to:
  /// **'البطاقة الائتمانية'**
  String get checkoutPaymentCard;

  /// Shown under an option the design draws but the app cannot offer yet.
  ///
  /// In ar, this message translates to:
  /// **'قريباً'**
  String get checkoutComingSoon;

  /// Order-summary row for the payment method's surcharge.
  ///
  /// In ar, this message translates to:
  /// **'رسوم الدفع'**
  String get checkoutPaymentFee;

  /// Order-summary row for the sum of every line above it.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get checkoutOrderTotal;

  /// Forward action of checkout step 3, from its own frame.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة الطلب'**
  String get checkoutToReview;

  /// Heading of the contact card on the review screen.
  ///
  /// In ar, this message translates to:
  /// **'معلومات الاتصال'**
  String get reviewContactSection;

  /// Heading of the delivery-address card on the review screen.
  ///
  /// In ar, this message translates to:
  /// **'عنوان التوصيل'**
  String get reviewAddressSection;

  /// Heading of the shipping card on the review screen.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الشحن'**
  String get reviewShippingSection;

  /// Heading of the payment card on the review screen. The frame draws no such card - it was added so the reviewed total matches what will actually be charged.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الدفع'**
  String get reviewPaymentSection;

  /// Link on a review card, returning to the step that collected it.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get reviewEdit;

  /// Heading over the ordered lines on the review screen.
  ///
  /// In ar, this message translates to:
  /// **'المنتجات'**
  String get reviewItems;

  /// Quantity of one line on the review screen, where it is read-only text rather than a stepper.
  ///
  /// In ar, this message translates to:
  /// **'الكمية: {count}'**
  String reviewQuantity(int count);

  /// Label before the postal code on the review screen's address card. Ends with a colon; the code follows it.
  ///
  /// In ar, this message translates to:
  /// **'الرمز البريدي:'**
  String get reviewPostalCode;

  /// The action that places the order. The last thing the shopper taps.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الطلب'**
  String get reviewConfirm;

  /// Delivery window on the review screen's shipping card, wrapping the method's own window.
  ///
  /// In ar, this message translates to:
  /// **'خلال {days}'**
  String reviewShippingEta(String days);

  /// Heading of the confirmation screen, the last thing checkout shows.
  ///
  /// In ar, this message translates to:
  /// **'تم تأكيد طلبك بنجاح!'**
  String get successTitle;

  /// Label before the order number on the confirmation screen. Ends with a colon; the number follows it.
  ///
  /// In ar, this message translates to:
  /// **'رقم الطلب:'**
  String get successOrderNumber;

  /// Supporting line under the order number. Deliberately says 'contact', not 'email': a guest order carries only a phone number.
  ///
  /// In ar, this message translates to:
  /// **'سنتواصل معك قريبًا لتأكيد التوصيل.'**
  String get successBody;

  /// Action opening the shopper's orders. Not shown to a guest, who has no account to track through.
  ///
  /// In ar, this message translates to:
  /// **'تتبع الطلب'**
  String get successTrackOrder;

  /// Action returning to the shop front.
  ///
  /// In ar, this message translates to:
  /// **'متابعة التسوق'**
  String get successKeepShopping;

  /// Heading of the order-history screen.
  ///
  /// In ar, this message translates to:
  /// **'طلباتي'**
  String get ordersTitle;

  /// Count beside the orders heading. Arabic has a dual and two plural bands, which a ternary cannot express.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{لا طلبات} =1{طلب واحد} =2{طلبان} few{{count} طلبات} many{{count} طلبًا} other{{count} طلب}}'**
  String ordersCount(int count);

  /// Heading of the empty order history.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات بعد'**
  String get ordersEmpty;

  /// Supporting line under the empty-orders heading.
  ///
  /// In ar, this message translates to:
  /// **'كل طلب تنهينه سيظهر هنا لتتابعيه'**
  String get ordersEmptyBody;

  /// Action on the empty order history, leading to the shop front.
  ///
  /// In ar, this message translates to:
  /// **'ابدئي التسوق'**
  String get ordersEmptyAction;

  /// Badge on an order card counting the lines its single thumbnail does not show.
  ///
  /// In ar, this message translates to:
  /// **'+{count}'**
  String ordersMoreItems(int count);

  /// Order status: placed, nothing done yet.
  ///
  /// In ar, this message translates to:
  /// **'قيد الانتظار'**
  String get orderStatusPending;

  /// Order status: accepted by the shop.
  ///
  /// In ar, this message translates to:
  /// **'مؤكد'**
  String get orderStatusConfirmed;

  /// Order status: being picked and packed.
  ///
  /// In ar, this message translates to:
  /// **'قيد التحضير'**
  String get orderStatusProcessing;

  /// Order status: handed to the courier.
  ///
  /// In ar, this message translates to:
  /// **'تم الشحن'**
  String get orderStatusShipped;

  /// Order status on a list badge, where the frame writes the short form.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get orderStatusDelivered;

  /// The same status on the details tracker, where the frame writes it in full. Two strings for one value, because the two frames word it differently.
  ///
  /// In ar, this message translates to:
  /// **'تم التوصيل'**
  String get orderStatusDeliveredLong;

  /// App-bar title of the order-details screen.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الطلب'**
  String get orderDetailTitle;

  /// Line above the order number. The date is formatted by intl for the locale.
  ///
  /// In ar, this message translates to:
  /// **'تم الطلب في {date}'**
  String orderPlacedOn(String date);

  /// The order number as the details screen heads it, with the hash the frame draws.
  ///
  /// In ar, this message translates to:
  /// **'الطلب #{number}'**
  String orderNumberHeading(String number);

  /// Heading over the five-stage tracker.
  ///
  /// In ar, this message translates to:
  /// **'حالة الطلب'**
  String get orderStatusHeading;

  /// Screen-reader label for the tracker, which is dots and words a reader would otherwise announce five times.
  ///
  /// In ar, this message translates to:
  /// **'حالة الطلب: {status}'**
  String orderStatusCurrent(String status);

  /// Heading over the ordered lines, counting quantities rather than lines.
  ///
  /// In ar, this message translates to:
  /// **'المنتجات ({count})'**
  String orderItemsHeading(int count);

  /// Heading of the delivery-address card on the details screen.
  ///
  /// In ar, this message translates to:
  /// **'عنوان التوصيل'**
  String get orderDeliveryAddress;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
