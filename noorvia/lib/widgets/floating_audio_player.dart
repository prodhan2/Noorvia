import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/providers/audio_provider.dart';

const _kPrimary = Color(0xFF1B6B3A);

// ═══════════════════════════════════════════════════════════════
// FloatingAudioPlayer — draggable, dismissible mini-player FAB
// ═══════════════════════════════════════════════════════════════
class FloatingAudioPlayer extends StatefulWidget {
  const FloatingAudioPlayer({super.key});

  @override
  State<FloatingAudioPlayer> createState() => _FloatingAudioPlayerState();
}

class _FloatingAudioPlayerState extends State<FloatingAudioPlayer>
    with SingleTickerProviderStateMixin {
  Offset _position = const Offset(16, 400);
  bool _expanded = false;
  late AnimationController _animCtrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _animCtrl.forward();
    } else {
      _animCtrl.reverse();
    }
  }

  String _fmt(Duration d) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(d.inMinutes.remainder(60))}:${p(d.inSeconds.remainder(60))}';
  }

  String _bn(dynamic n) {
    const e = ['0','1','2','3','4','5','6','7','8','9'];
    const b = ['০','১','২','৩','৪','৫','৬','৭','৮','৯'];
    var s = n.toString();
    for (int i = 0; i < e.length; i++) s = s.replaceAll(e[i], b[i]);
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    if (!audio.isVisible) return const SizedBox.shrink();

    final screenSize = MediaQuery.of(context).size;

    return Positioned(
      left: _position.dx.clamp(0, screenSize.width - 220),
      top: _position.dy.clamp(
          MediaQuery.of(context).padding.top + 60,
          screenSize.height - 200),
      child: GestureDetector(
        onPanUpdate: (d) {
          setState(() {
            _position = Offset(
              (_position.dx + d.delta.dx)
                  .clamp(0, screenSize.width - 220),
              (_position.dy + d.delta.dy).clamp(
                  MediaQuery.of(context).padding.top + 60,
                  screenSize.height - 200),
            );
          });
        },
        child: Material(
          color: Colors.transparent,
          child: AnimatedBuilder(
            animation: _expandAnim,
            builder: (_, __) => _buildPlayer(audio),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayer(AudioProvider audio) {
    return Container(
      width: _expanded ? 260 : 56,
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(_expanded ? 16 : 28),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _expanded ? _buildExpanded(audio) : _buildCollapsed(audio),
    );
  }

  // ── Collapsed: single icon button ────────────────────────
  Widget _buildCollapsed(AudioProvider audio) {
    return GestureDetector(
      onTap: _toggleExpand,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (audio.isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            else
              Icon(
                audio.isPlaying ? Icons.music_note : Icons.music_off,
                color: Colors.white,
                size: 24,
              ),
            // Pulse ring when playing
            if (audio.isPlaying)
              Positioned.fill(
                child: _PulseRing(),
              ),
          ],
        ),
      ),
    );
  }

  // ── Expanded: full mini-player ────────────────────────────
  Widget _buildExpanded(AudioProvider audio) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Collapse button
              GestureDetector(
                onTap: _toggleExpand,
                child: const Icon(Icons.music_note,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              // Surah name
              Expanded(
                child: Text(
                  audio.surahName,
                  style: GoogleFonts.hindSiliguri(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Close button
              GestureDetector(
                onTap: () => audio.stop(),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      color: Colors.white, size: 14),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Verse info
          if (audio.playingVerseId != null)
            Text(
              'আয়াত ${_bn(audio.playingVerseId!)}',
              style: GoogleFonts.hindSiliguri(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),

          const SizedBox(height: 8),

          // Progress bar
          if (audio.duration != null)
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                thumbColor: Colors.white,
                overlayColor: Colors.white.withValues(alpha: 0.1),
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 5),
                trackHeight: 2,
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 10),
              ),
              child: Slider(
                value: (audio.position ?? Duration.zero)
                    .inMilliseconds
                    .toDouble()
                    .clamp(
                        0,
                        audio.duration!.inMilliseconds
                            .toDouble()),
                max: audio.duration!.inMilliseconds.toDouble(),
                onChanged: (v) =>
                    audio.seek(Duration(milliseconds: v.toInt())),
              ),
            )
          else
            LinearProgressIndicator(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              color: Colors.white,
              minHeight: 2,
            ),

          // Time row
          if (audio.duration != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _fmt(audio.position ?? Duration.zero),
                    style: GoogleFonts.poppins(
                        color: Colors.white70, fontSize: 10),
                  ),
                  Text(
                    _fmt(audio.duration!),
                    style: GoogleFonts.poppins(
                        color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Controls row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Play/Pause
              GestureDetector(
                onTap: () {
                  if (audio.isPlaying) {
                    audio.pause();
                  } else {
                    audio.resume();
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    audio.isLoading
                        ? Icons.hourglass_empty
                        : (audio.isPlaying ? Icons.pause : Icons.play_arrow),
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Stop
              GestureDetector(
                onTap: () => audio.stop(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.stop,
                      color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Pulse animation ring ──────────────────────────────────────
class _PulseRing extends StatefulWidget {
  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(begin: 0.8, end: 1.4).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.scale(
        scale: _anim.value,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3 * (1.4 - _anim.value)),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
