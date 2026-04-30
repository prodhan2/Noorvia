// Stub implementation for non-web platforms
class WebAudioPlayer {
  String? _currentUrl;
  bool _playing = false;

  bool get isPlaying => _playing;
  String? get currentUrl => _currentUrl;

  void play(String url) {
    _currentUrl = url;
    _playing = true;
  }

  void pause() => _playing = false;
  void stop() { _playing = false; _currentUrl = null; }
  void dispose() { stop(); }
}
