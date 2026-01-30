import 'package:intl/intl.dart';

class Constants {
  static const String products = 'products';
}

class AppFormat {
  static final currency = NumberFormat('###,###');

  static String won(int amount) => '${currency.format(amount)}';
}