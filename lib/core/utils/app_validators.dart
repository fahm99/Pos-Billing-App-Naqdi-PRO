class AppValidators {
  static String? Function(String?) required(String message) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return message;
      }
      return null;
    };
  }

  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال السعر';
    }
    if (double.tryParse(value) == null) {
      return 'الرجاء إدخال رقم صحيح';
    }
    if (double.parse(value) < 0) {
      return 'لا يمكن أن يكون السعر سالباً';
    }
    return null;
  }
}
