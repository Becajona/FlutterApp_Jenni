import 'package:intl/intl.dart';

class MoneyFmt {
  MoneyFmt._();
  static final _mx = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

  static String mx(num value) => _mx.format(value);
}
