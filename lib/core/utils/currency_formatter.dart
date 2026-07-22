class CurrencyFormatter {
  static String format(double amount) {
    String number = amount.abs().toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return 'Rp $number';
  }
}
