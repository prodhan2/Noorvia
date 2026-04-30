import 'package:web/web.dart' as web;
import 'dart:js_interop';

class WebAudioPlayer {
  web.HTMLAudioElement? _element;
  bool _playing = false;
  String? _currentUrl;

  bool get isPlaying => _playing;

  void play(String url) {
    if (_currentUrl == url && _element != null) {
      _element!.play();
      _playing = true;
      return;
    }
    _element?.pause();
    final el = web.HTMLAudioElement();
    el.src = url;
    el.crossOrigin = 'anonymous';
    el.addEventListener('ended', ((_) { _playing = false; }).toJS);
    el.addEventListener('error', ((_) { _playing = false; }).toJS);
    el.play();
    _element = el;
    _currentUrl = url;
    _playing = true;
  }

  void pause() {
    _element?.pause();
    _playing = false;
  }

  void stop() {
    _element?.pause();
    final el = _element;
    if (el != null) el.currentTime = 0;
    _playing = false;
    _currentUrl = null;
  }

  void dispose() {
    stop();
    _element = null;
  }
}
