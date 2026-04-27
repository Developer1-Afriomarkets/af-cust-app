/// Port of the web's `handlePricing.ts` — locale-aware currency formatting.
///
/// Medusa stores amounts in the smallest currency unit (kobo, cents, etc).
/// This helper converts to display values with proper symbols and formatting.
class PriceHelper {
  // Currency → minor-unit factor (divide amount by this to get major units)
  static const Map<String, int> _currencyFactors = {
    'NGN': 100, // naira → kobo
    'USD': 100, // dollar → cent
    'EUR': 100, // euro → cent
    'GBP': 100, // pound → penny
    'JPY': 1, // yen (no minor unit)
    'GHS': 100, // cedi → pesewa
    'KES': 100, // shilling → cent
    'ZAR': 100, // rand → cent
    'XOF': 1, // CFA franc (no minor unit)
    'XAF': 1, // Central African CFA franc
    'EGP': 100, // Egyptian pound → piaster
  };

  // Currency → symbol for quick display
  static const Map<String, String> _currencySymbols = {
    'NGN': '₦',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'GHS': 'GH₵',
    'KES': 'KSh',
    'ZAR': 'R',
    'XOF': 'CFA',
    'XAF': 'FCFA',
    'EGP': 'E£',
  };

  /// Convert a Medusa minor-unit amount to a formatted price string.
  ///
  /// Example: `formatPrice(30000, 'NGN')` → `"₦300.00"`
  /// Example: `formatPrice(1500, 'USD')` → `"\$15.00"`
  static String formatPrice(int minorAmount, String? currencyCode) {
    if (currencyCode == null || currencyCode.isEmpty) {
      return 'Price unavailable';
    }

    final currency = currencyCode.toUpperCase();
    final factor = _currencyFactors[currency] ?? 100;
    final majorValue = minorAmount / factor;
    final symbol = _currencySymbols[currency] ?? currency;

    // No decimal places for JPY, XOF, etc.
    if (factor == 1) {
      return '$symbol${_addThousandsSep(majorValue.toStringAsFixed(0))}';
    }

    // Format with 2 decimal places and thousands separator
    return '$symbol${_addThousandsSep(majorValue.toStringAsFixed(2))}';
  }

  /// Adds thousands separators (commas) to a numeric string.
  static String _addThousandsSep(String value) {
    final parts = value.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? '.${parts[1]}' : '';

    final buffer = StringBuffer();
    int count = 0;
    for (int i = intPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0 && intPart[i] != '-') {
        buffer.write(',');
      }
      buffer.write(intPart[i]);
      count++;
    }
    return buffer.toString().split('').reversed.join() + decPart;
  }

  /// Convert a major-unit value to minor units for API calls.
  ///
  /// Example: `toMinorUnit(300, 'NGN')` → `30000`
  static int toMinorUnit(double majorValue, String currencyCode) {
    final factor = _currencyFactors[currencyCode.toUpperCase()] ?? 100;
    return (majorValue * factor).round();
  }

  /// Convert minor units to major units (raw number, no formatting).
  static double toMajorUnit(int minorAmount, String currencyCode) {
    final factor = _currencyFactors[currencyCode.toUpperCase()] ?? 100;
    return minorAmount / factor;
  }

  /// Get the currency symbol for a given currency code.
  static String getSymbol(String currencyCode) {
    return _currencySymbols[currencyCode.toUpperCase()] ??
        currencyCode.toUpperCase();
  }
}
