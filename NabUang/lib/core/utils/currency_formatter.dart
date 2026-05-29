class CurrencyFormatter {
  /// Format: Rp 3.845.000
  static String format(double amount) {
    final digits = amount.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    int count = 0;
    for (int i = digits.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
      count++;
    }
    final numberPart = buffer.toString().split('').reversed.join();
    return 'Rp $numberPart';
  }

  /// Format kompak: Rp 3,8jt / Rp 500rb
  static String compact(double v) {
    if (v >= 1000000) return 'Rp ${(v / 1000000).toStringAsFixed(1)}jt';
    if (v >= 1000) return 'Rp ${(v / 1000).toStringAsFixed(0)}rb';
    return 'Rp ${v.toStringAsFixed(0)}';
  }

  /// Parse string bertitik ke double: "3.845.000" → 3845000
  static double parse(String formatted) {
    final clean = formatted.replaceAll('.', '');
    return double.tryParse(clean) ?? 0;
  }

  /// Format angka dengan titik ribuan: "3845000" → "3.845.000"
  static String addSeparator(String digits) {
    if (digits.isEmpty) return '';
    final clean = digits.replaceAll('.', '');
    if (clean.isEmpty) return '';
    final buffer = StringBuffer();
    int count = 0;
    for (int i = clean.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write('.');
      buffer.write(clean[i]);
      count++;
    }
    return buffer.toString().split('').reversed.join();
  }
}
