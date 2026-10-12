import 'package:intl/intl.dart';

class Formatters {
  static final _currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  static final _compactCurrencyFormatter = NumberFormat.compactCurrency(symbol: '\$', decimalDigits: 1);
  static final _compactNumberFormatter = NumberFormat.compact();
  static final _fullCurrencyFormatter = NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 0);

  static String formatCurrency(double value) {
    return _fullCurrencyFormatter.format(value);
  }

  static String formatCompactCurrency(double value) {
    if (value >= 10000) {
      return _compactCurrencyFormatter.format(value);
    }
    return _currencyFormatter.format(value);
  }

  static String formatFullCurrency(double value) {
    return _fullCurrencyFormatter.format(value);
  }

  static String formatNumber(double value) {
    if (value >= 10000) {
      return _compactNumberFormatter.format(value);
    }
    return NumberFormat('#,##0').format(value);
  }

  static num parseNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    if (value is String) {
      final sanitized = value.replaceAll(',', '').replaceAll('\$', '');
      return double.tryParse(sanitized) ?? 0;
    }
    return 0;
  }
}
