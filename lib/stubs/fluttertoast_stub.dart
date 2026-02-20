// Stub for fluttertoast compatibility
class Fluttertoast {
  static Future<bool?> showToast({
    required String msg,
    int? toastLength,
    int? gravity,
    int? timeInSecForIosWeb,
    dynamic backgroundColor,
    dynamic textColor,
    double? fontSize,
  }) async {
    // Silent - don't show anything
    print("Toast (muted): $msg");
    return true;
  }

  static Future<bool?> cancel() async {
    return true;
  }
}

enum Toast { LENGTH_SHORT, LENGTH_LONG }
