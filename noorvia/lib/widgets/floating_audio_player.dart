import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/providers/audio_provider.dart';

const _kPrimary = Color(0xFF1B6B3A);
const _kPrimaryDark = Color(0xFF0F4D2A);

class FloatingAudioPlayer extends StatefulWidget {
  const FloatingAudioPlayer({super.key});

  @override
  State<FloatingAudioPlayer> createState() => _FloatingAudioPlayerState();
}

class _FloatingAudioPlayerState extends State<FloatingAudioPlayer>
    with TickerProviderStateMixin {
  Offset? _pos;
  bool _expanded = false;
  bool _isDragging = false;

  late final AnimationController _appearCtrl;
  late final Animation<double> _appearAnim;

  static const double _fabSize = 58.0;
  static const double _cardW = 270.0;
  static const double _cardH = 200.0;
  static const double _edgePad = 16.0;

  @override
  void initState() {
    super.initState();
    _appearCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _appearAnim = CurvedAnimation(
      parent: _appearCtrl,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _appearCtrl.dispose();
    super.dispose();
  }

  void _initPos(Size screen) {
    _pos ??= Offset(
      screen.width - _fabSize - _edgePad,
      screen.height - _fabSize - 130,
    );
  }

  void _snapToEdge(Size screen) {
    if (_pos == null) return;
    final mid = screen.width / 2;
    final targetX = (_pos!.dx + _fabSize / 2) < mid
        ? _edgePad
        : screen.width - _fabSize - _edgePad;
    final topPad = MediaQuery.of(context).padding.top;
    final targetY =
        _pos!.dy.clamp(topPad + 60.0, screen.height - _fabSize - 80.0);
    setState(() => _pos = Offset(targetX, targetY));
  }

  void _toggleExpand() => setState(() => _expanded = !_expanded);

  String _fmt(Duration d) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(d.inMinutes.remainder(60))}:${p(d.inSeconds.remainder(60))}';
  }

  String _bn(dynamic n) {
    const e = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const b = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    var s = n.toString();
    for (int i = 0; i < e.length; i++) s = s.replaceAll(e[i], b[i]);
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final screen = MediaQuery.of(context).size;
    final topPad = MediaQuery.of(context).padding.top;

    _initPos(screen);

    // Animate in/out based on visibility
    if (audio.isVisible) {
      if (!_appearCtrl.isCompleted && !_appearCtrl.isAnimating) {
        _appearCtrl.forward();
      }
    } else {
      if (_appearCtrl.value > 0 && !_appearCtrl.isAnimating) {
        _appearCtrl.reverse().then((_) {
          if (mounted && _expanded) setState(() => _expanded = false);
        });
      }
      if (_appearCtrl.isDismissed) return const SizedBox.shrink();
    }

    final currentW = _expanded ? _cardW : _fabSize;
    final currentH = _expanded ? _cardH : _fabSize;

    final clampedX =
        _pos!.dx.clamp(_edgePad, screen.width - currentW - _edgePad);
    final clampedY =
        _pos!.dy.clamp(topPad + 60.0, screen.height - currentH - 60.0);

    return Positioned(
      left: clampedX,
      top: clampedY,
      child: ScaleTransition(
        scale: _appearAnim,
        child: GestureDetector(
          onPanStart: (_) => setState(() => _isDragging = true),
          onPanUpdate: (d) {
            setState(() {
              _pos = Offset(
                (_pos!.dx + d.delta.dx)
                    .clamp(_edgePad, screen.width - currentW - _edgePad),
                (_pos!.dy + d.delta.dy)
                    .clamp(topPad + 60.0, screen.height - currentH - 60.0),
              );
            });
          },
          onPanEnd: (_) {
            setState(() => _isDragging = false);
            if (!_expanded) _snapToEdge(screen);
          },
          child: _expanded ? _buildCard(audio) : _buildFab(audio),
        ),
      ),
    );
  }

  // ── Collapsed FAB ─────────────────────────────────────────
  Widget _buildFab(AudioProvider audio) {
    return GestureDetector(
      onTap: _toggleExpand,
      child: Container(
        width: _fabSize,
        height: _fabSize,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E8B57), _kPrimaryDark],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _kPrimary.withValues(alpha: _isDragging ? 0.65 : 0.5),
              blurRadius: _isDragging ? 22 : 16,
              spreadRadius: _isDragging ? 3 : 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (audio.isPlaying) const _PulseRing(),
            if (audio.isLoading)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            else
              Icon(
                audio.isPlaying
                    ? Icons.graphic_eq_rounded
                    : Icons.music_note_rounded,
                color: Colors.white,
                size: 26,
              ),
          ],
        ),
      ),
    );
  }

  // ── Expanded card ─────────────────────────────────────────
  Widget _buildCard(AudioProvider audio) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: _cardW,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B6B3A), _kPrimaryDark],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _kPrimary.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _toggleExpand,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          audio.surahName.isNotEmpty
                              ? audio.surahName
                              : 'তিলাওয়াত',
                          style: GoogleFonts.hindSiliguri(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            height: 1.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (audio.playingVerseId != null)
                          Text(
                            'আয়াত ${_bn(audio.playingVerseId!)}',
                            style: GoogleFonts.hindSiliguri(
                                color: Colors.white60, fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                  // Close — stop audio
                  GestureDetector(
                    onTap: () {
                      setState(() => _expanded = false);
                      audio.stop();
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: audio.duration != null
                  ? Column(
                      children: [
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: Colors.white,
                            inactiveTrackColor:
                                Colors.white.withValues(alpha: 0.25),
                            thumbColor: Colors.white,
                            overlayColor:
                                Colors.white.withValues(alpha: 0.15),
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 5),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 12),
                            trackHeight: 3,
                          ),
                          child: SizedBox(
                            height: 28,
                            child: Slider(
                              value: (audio.position ?? Duration.zero)
                                  .inMilliseconds
                                  .toDouble()
                                  .clamp(
                                      0,
                                      audio.duration!.inMilliseconds
                                          .toDouble()),
                              max: audio.duration!.inMilliseconds.toDouble(),
                              onChanged: (v) => audio
                                  .seek(Duration(milliseconds: v.toInt())),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_fmt(audio.position ?? Duration.zero),
                                  style: GoogleFonts.poppins(
                                      color: Colors.white60, fontSize: 10)),
                              Text(_fmt(audio.duration!),
                                  style: GoogleFonts.poppins(
                                      color: Colors.white60, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.2),
                          color: Colors.white,
                          minHeight: 3,
                        ),
                      ),
                    ),
            ),

            // Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ControlBtn(
                    size: 44,
                    icon: audio.isLoading
                        ? Icons.hourglass_top_rounded
                        : (audio.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded),
                    iconSize: 26,
                    onTap: () =>
                        audio.isPlaying ? audio.pause() : audio.resume(),
                    highlight: true,
                  ),
                  const SizedBox(width: 16),
                  _ControlBtn(
                    size: 36,
                    icon: Icons.stop_rounded,
                    iconSize: 20,
                    onTap: () {
                      setState(() => _expanded = false);
                      audio.stop();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Control button ───────────────────────────────────────────
class _ControlBtn extends StatelessWidget {
  final double size;
  final IconData icon;
  final double iconSize;
  final VoidCallback onTap;
  final bool highlight;

  const _ControlBtn({
    required this.size,
    required this.icon,
    required this.iconSize,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: highlight
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: highlight
              ? Border.all(
                  color: Colors.white.withValues(alpha: 0.4), width: 1.5)
              : null,
        ),
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }
}

// ─── Pulse ring ───────────────────────────────────────────────
class _PulseRing extends StatefulWidget {
  const _PulseRing();

  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _scale = Tween<double>(begin: 1.0, end: 1.7)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = Tween<double>(begin: 0.5, end: 0.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: _opacity.value),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
