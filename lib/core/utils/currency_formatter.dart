class CurrencyFormatter {
  static String format(double amount) {
    final isNegative = amount < 0;
    String number = amount.abs().toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return '${isNegative ? "- " : ""}Rp $number';
  }
}
