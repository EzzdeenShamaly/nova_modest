// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Nova Modest';

  @override
  String get brandName => 'NOVA MODEST';

  @override
  String get splashTagline => 'Modern modesty, for every day';

  @override
  String get onboardingTitle1 => 'Shop your elegance with ease';

  @override
  String get onboardingBody1 =>
      'Discover the latest modest fashion, chosen with care to suit your refined taste.';

  @override
  String get onboardingTitle2 => 'Modest designs with a modern touch';

  @override
  String get onboardingBody2 =>
      'We blend heritage and modernity in unique pieces that express your character with complete elegance.';

  @override
  String get onboardingTitle3 => 'Fast, reliable delivery to your door';

  @override
  String get onboardingBody3 =>
      'A secure shopping experience and swift delivery for every order, handled with care.';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get authMethodTitle => 'Sign in or create an account';

  @override
  String get authMethodSubtitle =>
      'Track your orders and save your favourite addresses';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authOr => 'or';

  @override
  String get authContinueWithEmail => 'Continue with email';

  @override
  String get authContinueAsGuest => 'Continue as a guest';

  @override
  String get verifyEmailTitle => 'Check your email';

  @override
  String verifyEmailSubtitle(String email) {
    return 'We sent a 6-digit code to $email';
  }

  @override
  String get verifyEmailConfirm => 'Confirm';

  @override
  String get verifyEmailResend => 'Resend';

  @override
  String get verifyEmailNoCode => 'Did not get the code?';

  @override
  String get verifyEmailCodeIncomplete => 'Enter the 6-digit code';

  @override
  String get navHome => 'Home';

  @override
  String get navCategories => 'Categories';

  @override
  String get navCart => 'Cart';

  @override
  String get navProfile => 'Account';

  @override
  String get homeHeroTagline => 'Modern modesty, for every day';

  @override
  String get homeHeroCta => 'Shop now';

  @override
  String get homeCategoryAll => 'All';

  @override
  String get homeFeaturedTitle => 'Featured';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeEmpty => 'No products yet';

  @override
  String get homeFilterEmpty => 'Nothing in this category';

  @override
  String get homeFavourite => 'Add to favourites';

  @override
  String get homeSearch => 'Search';

  @override
  String get currencySymbol => 'SAR';

  @override
  String get productSoldOut => 'Sold out';

  @override
  String get productListFilter => 'Filter';

  @override
  String get productListEmpty => 'Nothing in this category yet';

  @override
  String get productListFilterEmpty => 'Nothing matches this filter';

  @override
  String get productColour => 'Colour';

  @override
  String get productSize => 'Size';

  @override
  String get productSizeGuide => 'Size guide';

  @override
  String get productDetails => 'Details';

  @override
  String get productAddToCart => 'Add to cart';

  @override
  String get productAddedToCart => 'Added to your cart';

  @override
  String get productShare => 'Share';

  @override
  String get productDecreaseQuantity => 'Decrease quantity';

  @override
  String get productIncreaseQuantity => 'Increase quantity';

  @override
  String productImageCount(int current, int total) {
    return '$current of $total';
  }

  @override
  String get loginTitle => 'Sign in';

  @override
  String get emailLabel => 'Email';

  @override
  String get logoutButton => 'Sign out';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emailInvalid => 'Enter a valid email address';

  @override
  String get retry => 'Retry';

  @override
  String get homeTitle => 'Home';

  @override
  String welcomeUser(String name) {
    return 'Welcome, $name';
  }

  @override
  String get failureNetwork => 'No internet connection.';

  @override
  String get failureServer => 'Server error. Please try again later.';

  @override
  String get failureNotFound => 'Not found.';

  @override
  String get failureUnauthorized =>
      'Your session expired. Please sign in again.';

  @override
  String get failureValidation => 'Please check the information you entered.';

  @override
  String get failureCache => 'Local data unavailable.';

  @override
  String get failureUnknown => 'Something went wrong.';

  @override
  String get cartTitle => 'Cart';

  @override
  String cartVariant(String colour, String size) {
    return 'Colour: $colour | Size: $size';
  }

  @override
  String cartVariantColour(String colour) {
    return 'Colour: $colour';
  }

  @override
  String cartVariantSize(String size) {
    return 'Size: $size';
  }

  @override
  String get cartRemoveItem => 'Remove from cart';

  @override
  String get cartSubtotal => 'Subtotal';

  @override
  String get cartShipping => 'Shipping';

  @override
  String get cartTotal => 'Total';

  @override
  String get cartCheckout => 'Proceed to checkout';

  @override
  String get cartEmpty => 'Your cart is empty';

  @override
  String get cartEmptyBody => 'Add anything you like and you\'ll find it here.';

  @override
  String get cartEmptyCta => 'Shop now';

  @override
  String get cartViewCart => 'View cart';

  @override
  String get filterTitle => 'Filters';

  @override
  String get filterClose => 'Close';

  @override
  String get filterClearAll => 'Clear all';

  @override
  String get filterCategory => 'Category';

  @override
  String get filterStyle => 'Style';

  @override
  String get filterPriceRange => 'Price range';

  @override
  String filterPriceRangeValue(String min, String max) {
    return '$min - $max';
  }

  @override
  String get filterReset => 'Reset';

  @override
  String filterApply(int count) {
    return 'Show results ($count)';
  }

  @override
  String get searchHint => 'Search for what you love';

  @override
  String get searchClear => 'Clear search';

  @override
  String get searchRecent => 'Recent searches';

  @override
  String get searchRemoveTerm => 'Remove from recent searches';

  @override
  String get searchTrending => 'Trending';

  @override
  String get searchExploreCategories => 'Explore categories';

  @override
  String searchResultCount(int count, String query) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results for «$query»',
      one: '1 result for «$query»',
      zero: 'No results for «$query»',
    );
    return '$_temp0';
  }

  @override
  String get searchSort => 'Sort';

  @override
  String get searchSortRelevance => 'Most relevant';

  @override
  String get searchSortPriceAscending => 'Price: low to high';

  @override
  String get searchSortPriceDescending => 'Price: high to low';

  @override
  String get searchEmptyTitle => 'No results';

  @override
  String searchEmptyBody(String query) {
    return 'Nothing matched «$query». Try another word.';
  }

  @override
  String get searchFilterEmpty => 'No results with these filters';

  @override
  String get profileMyOrders => 'My orders';

  @override
  String get profilePersonalInfo => 'Personal information';

  @override
  String get profileAddresses => 'Addresses';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileNotifications => 'Notifications';

  @override
  String get profileHelp => 'Help & support';

  @override
  String get profileTerms => 'Terms & conditions';

  @override
  String get profileLogoutConfirm => 'Sign out of your account?';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get languageName => 'English';

  @override
  String get personalInfoSubtitle =>
      'Keep your details up to date so your account stays current.';

  @override
  String get personalInfoFullName => 'Full name';

  @override
  String get personalInfoEmailLocked => 'Your email address cannot be changed.';

  @override
  String get personalInfoPhone => 'Phone number';

  @override
  String get personalInfoSave => 'Save changes';

  @override
  String get personalInfoSaved => 'Your changes were saved';

  @override
  String get personalInfoNameRequired => 'A name is required';

  @override
  String get personalInfoPhoneInvalid => 'Enter a valid phone number';

  @override
  String get personalInfoDiscardTitle => 'Unsaved changes';

  @override
  String get personalInfoDiscardBody =>
      'You have edits that have not been saved. Leave without saving?';

  @override
  String get personalInfoDiscard => 'Leave without saving';

  @override
  String get addressListTitle => 'My addresses';

  @override
  String get addressDefaultBadge => 'Default';

  @override
  String get addressSetDefault => 'Set as default';

  @override
  String get addressEdit => 'Edit address';

  @override
  String get addressDelete => 'Delete address';

  @override
  String get addressDeleteConfirm =>
      'This address will be removed for good. Continue?';

  @override
  String get addressAdd => 'Add a new address';

  @override
  String get addressEmpty => 'No saved addresses';

  @override
  String get addressEmptyBody => 'Add one and your order will reach you sooner';

  @override
  String get addressLabelField => 'Address name';

  @override
  String get addressKind => 'Type';

  @override
  String get addressKindHome => 'Home';

  @override
  String get addressKindWork => 'Work';

  @override
  String get addressKindOther => 'Other';

  @override
  String get addressRecipient => 'Recipient name';

  @override
  String get addressCountry => 'Country';

  @override
  String get addressRegion => 'District';

  @override
  String get addressCity => 'City';

  @override
  String get addressPostalCode => 'Postal code';

  @override
  String get addressStreet => 'Street address';

  @override
  String get addressStreetHint => 'Street name, building number…';

  @override
  String get addressNotes => 'Additional notes';

  @override
  String get addressNotesHint => 'A landmark, a preferred delivery time…';

  @override
  String get addressMakeDefault => 'Make this my default address';

  @override
  String get addressSave => 'Save address';

  @override
  String get addressSaved => 'Address saved';

  @override
  String get addressFieldRequired => 'This field is required';

  @override
  String get languageExplanation =>
      'The interface updates immediately when you choose.';

  @override
  String get languageNotSaved =>
      'The language changed, but your choice could not be saved.';

  @override
  String get helpFaqTitle => 'Frequently asked questions';

  @override
  String get helpContactTitle => 'Contact us';

  @override
  String get helpFaqSignInQuestion => 'How do I sign in?';

  @override
  String get helpFaqSignInAnswer =>
      'With your Google account, or with a six-digit code sent to your email. There is no password in this app.';

  @override
  String get helpFaqEmailQuestion => 'Can I change my email address?';

  @override
  String get helpFaqEmailAnswer =>
      'Your email is tied to your account and cannot be changed in the app. Your name and phone number can be edited under Personal information.';

  @override
  String get helpFaqLanguageQuestion => 'How do I change the app\'s language?';

  @override
  String get helpFaqLanguageAnswer =>
      'Under Account, then Language. The interface changes immediately, with no restart.';

  @override
  String get helpFaqAddressQuestion => 'How do I manage my addresses?';

  @override
  String get helpFaqAddressAnswer =>
      'Under Account, then Addresses. You can add, edit and remove them, and mark one as the default your orders go to.';

  @override
  String get helpContactEmail => 'Email';

  @override
  String get helpContactPhone => 'Support phone';

  @override
  String get helpCopy => 'Copy';

  @override
  String get helpCopied => 'Copied';

  @override
  String get termsPlaceholder =>
      'The full terms and conditions will be added here.';

  @override
  String get termsPlaceholderNote =>
      'The final version is being prepared. For questions, reach us through Help & support.';

  @override
  String get notificationsOrders => 'Order updates';

  @override
  String get notificationsOrdersDescription =>
      'Order confirmation, shipping and delivery updates.';

  @override
  String get notificationsPromotions => 'Offers and sales';

  @override
  String get notificationsPromotionsDescription =>
      'Campaigns, sales and new arrivals.';

  @override
  String get notificationsDeviceNote =>
      'Your phone\'s settings decide whether notifications arrive at all. If they are turned off there, nothing will reach you whatever you choose here.';

  @override
  String get checkoutContactTitle => 'Contact information';

  @override
  String get checkoutAddressTitle => 'Delivery address';

  @override
  String get checkoutPaymentTitle => 'Shipping and payment';

  @override
  String get checkoutReviewTitle => 'Review your order';

  @override
  String get checkoutSuccessTitle => 'Order placed';

  @override
  String get checkoutFullName => 'Full name';

  @override
  String get checkoutFullNameHint => 'Enter your full name';

  @override
  String get checkoutPhoneHint => '59 123 4567';

  @override
  String checkoutStepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get checkoutSavedAddresses => 'Saved addresses';

  @override
  String get checkoutNewAddress => 'New address';

  @override
  String get checkoutSaveAndContinue => 'Save and continue';

  @override
  String get checkoutShippingMethod => 'Shipping method';

  @override
  String get checkoutPaymentMethod => 'Payment method';

  @override
  String get checkoutShippingStandard => 'Standard delivery';

  @override
  String get checkoutShippingStandardEta => '3-5 business days';

  @override
  String get checkoutPaymentCod => 'Cash on delivery';

  @override
  String checkoutPaymentCodFee(String fee) {
    return 'Extra fee $fee';
  }

  @override
  String get checkoutPaymentCard => 'Credit card';

  @override
  String get checkoutComingSoon => 'Coming soon';

  @override
  String get checkoutPaymentFee => 'Payment fee';

  @override
  String get checkoutOrderTotal => 'Total';

  @override
  String get checkoutToReview => 'Review your order';

  @override
  String get reviewContactSection => 'Contact information';

  @override
  String get reviewAddressSection => 'Delivery address';

  @override
  String get reviewShippingSection => 'Shipping method';

  @override
  String get reviewPaymentSection => 'Payment method';

  @override
  String get reviewEdit => 'Edit';

  @override
  String get reviewItems => 'Items';

  @override
  String reviewQuantity(int count) {
    return 'Quantity: $count';
  }

  @override
  String get reviewPostalCode => 'Postal code:';

  @override
  String get reviewConfirm => 'Place order';

  @override
  String reviewShippingEta(String days) {
    return 'Within $days';
  }

  @override
  String get successTitle => 'Your order is confirmed!';

  @override
  String get successOrderNumber => 'Order number:';

  @override
  String get successBody => 'We will contact you shortly to confirm delivery.';

  @override
  String get successTrackOrder => 'Track order';

  @override
  String get successKeepShopping => 'Keep shopping';

  @override
  String get ordersTitle => 'My orders';

  @override
  String ordersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count orders',
      one: '1 order',
      zero: 'No orders',
    );
    return '$_temp0';
  }

  @override
  String get ordersEmpty => 'No orders yet';

  @override
  String get ordersEmptyBody => 'Every order you place will show up here';

  @override
  String get ordersEmptyAction => 'Start shopping';

  @override
  String ordersMoreItems(int count) {
    return '+$count';
  }

  @override
  String get orderStatusPending => 'Pending';

  @override
  String get orderStatusConfirmed => 'Confirmed';

  @override
  String get orderStatusProcessing => 'Processing';

  @override
  String get orderStatusShipped => 'Shipped';

  @override
  String get orderStatusDelivered => 'Completed';

  @override
  String get orderStatusDeliveredLong => 'Delivered';

  @override
  String get orderDetailTitle => 'Order details';

  @override
  String orderPlacedOn(String date) {
    return 'Placed on $date';
  }

  @override
  String orderNumberHeading(String number) {
    return 'Order #$number';
  }

  @override
  String get orderStatusHeading => 'Order status';

  @override
  String orderStatusCurrent(String status) {
    return 'Order status: $status';
  }

  @override
  String orderItemsHeading(int count) {
    return 'Items ($count)';
  }

  @override
  String get orderDeliveryAddress => 'Delivery address';
}
