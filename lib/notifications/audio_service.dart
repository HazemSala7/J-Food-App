import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  Future<void> playSound() async {
    if (_isPlaying) return;
    _isPlaying = true;
    try {
      // Use the loud alarm sound
      await _audioPlayer.setAsset('assets/order_alarm.wav');
      await _audioPlayer.setVolume(1.0); // MAX volume
      await _audioPlayer.setLoopMode(LoopMode.one); // Loop until stopped
      await _audioPlayer.play();

      // Vibrate with the sound
      _startVibration();
    } catch (e) {
      _isPlaying = false;
      print('Error playing sound: $e');
    }
  }

  void _startVibration() async {
    // Continuous vibration pattern while sound is playing
    while (_isPlaying) {
      HapticFeedback.vibrate();
      await Future.delayed(Duration(milliseconds: 500));
    }
  }

  Future<void> stopSound() async {
    _isPlaying = false;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.seek(Duration.zero);
    } catch (e) {
      print('Error stopping sound: $e');
    }
  }

  void dispose() {
    _isPlaying = false;
    _audioPlayer.dispose();
  }
}
