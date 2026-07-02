import 'package:audioplayers/audioplayers.dart';

/// Plays the UI sounds + home theme music. All clips are the assets copied 1:1
/// from the original launcher.
class Sounds {
  Sounds._();
  static final Sounds I = Sounds._();

  final AudioPlayer _music = AudioPlayer(playerId: 'music');
  final AudioPlayer _sfx = AudioPlayer(playerId: 'sfx');
  bool _started = false;

  Future<void> startMusic() async {
    if (_started) return;
    _started = true;
    try {
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.setVolume(0.55);
      await _music.play(AssetSource('audio/home_theme.ogg'));
    } catch (_) {/* audio backend may be missing on a headless box */}
  }

  /// Pause the home theme while an app is in the foreground.
  Future<void> pauseMusic() async {
    try {
      await _music.pause();
    } catch (_) {}
  }

  /// Resume the home theme when you return to the launcher.
  Future<void> resumeMusic() async {
    if (!_started) return;
    try {
      await _music.resume();
    } catch (_) {}
  }

  Future<void> _play(String file, {double volume = 1.0}) async {
    try {
      await _sfx.stop();
      await _sfx.setVolume(volume);
      await _sfx.play(AssetSource('audio/$file'));
    } catch (_) {}
  }

  void navigate() => _play('navigation.wav', volume: 0.9);
  void select() => _play('open_app.wav');
  void back() => _play('close.wav');
  void menu() => _play('menu_navigate.wav');

  void dispose() {
    _music.dispose();
    _sfx.dispose();
  }
}
