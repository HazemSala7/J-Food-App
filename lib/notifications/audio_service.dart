import 'package:just_audio/just_audio.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> playSound() async {
    // Load the audio asset and play it
    try {
      await _audioPlayer.setAsset('assets/order_sound.wav');
      await _audioPlayer.setLoopMode(LoopMode.one); // Loop the sound
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing sound: $e'); // Handle any errors
    }
  }

  Future<void> stopSound() async {
    // Stop the audio playback
    try {
      await _audioPlayer.stop();
      await _audioPlayer
          .seek(Duration.zero); // Reset playback position if needed
    } catch (e) {
      print('Error stopping sound: $e'); // Handle any errors
    }
  }

  void dispose() {
    // Dispose of the audio player when no longer needed
    _audioPlayer.dispose();
  }
}
