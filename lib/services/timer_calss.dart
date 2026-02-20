import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;

class TimerService with ChangeNotifier {
  Map<int, DateTime> _startTimes = {};
  Map<int, int> _durations = {}; // in seconds

  Timer? _ticker; // single ticker to refresh UI every second

  TimerService() {
    print("TimerService initialized");
    loadRemainingTimes();
    _startTicker();
  }

  void startTimer(int orderId, int initialMinutes) {
    final duration = initialMinutes * 60; // in seconds
    _startTimes[orderId] = DateTime.now();
    _durations[orderId] = duration;
    saveRemainingTimes();
    notifyListeners();
  }

  void stopTimer(int orderId) {
    _startTimes.remove(orderId);
    _durations.remove(orderId);
    saveRemainingTimes();
    notifyListeners();
  }

  int getRemainingTime(int orderId) {
    if (!_startTimes.containsKey(orderId) || !_durations.containsKey(orderId)) {
      return 0;
    }
    final start = _startTimes[orderId]!;
    final duration = _durations[orderId]!;
    final elapsed = DateTime.now().difference(start).inSeconds;
    final remaining = duration - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  String formatTime(int remainingTime) {
    int minutes = remainingTime ~/ 60;
    int seconds = remainingTime % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> loadRemainingTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('timers_data');
    if (saved != null) {
      final decoded = jsonDecode(saved) as Map<String, dynamic>;
      _startTimes = decoded.map((key, value) =>
          MapEntry(int.parse(key), DateTime.parse(value['start'])));
      _durations = decoded.map(
          (key, value) => MapEntry(int.parse(key), value['duration'] as int));
    }
    notifyListeners();
  }

  Future<void> saveRemainingTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _startTimes.map((orderId, startTime) => MapEntry(
            orderId.toString(), {
          'start': startTime.toIso8601String(),
          'duration': _durations[orderId]
        }));
    prefs.setString('timers_data', jsonEncode(data));
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners(); // UI refresh every second
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // Future<void> changeOrderStatus(String orderId, String status) async {
  //   try {
  //     final response = await http.post(
  //       Uri.parse('https://hrsps.com/login/api/change_order_status'),
  //       headers: <String, String>{'Content-Type': 'application/json'},
  //       body:
  //           jsonEncode(<String, String>{'order_id': orderId, 'status': status}),
  //     );
  //     if (response.statusCode != 200 && response.statusCode != 201) {
  //       throw Exception('Failed to change order status');
  //     }
  //   } catch (e) {
  //     print('Error changing order status: $e');
  //   }
  // }
}
