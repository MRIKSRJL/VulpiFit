import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bouton mission style néon / sport + retour haptique au clic.
/// La célébration massive (confettis + son) est déclenchée par l’écran parent après succès API.
class SatisfyingMissionButton extends StatefulWidget {
  const SatisfyingMissionButton({
    super.key,
    required this.title,
    required this.points,
    required this.isCompleted,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final int points;
  final bool isCompleted;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<SatisfyingMissionButton> createState() => _SatisfyingMissionButtonState();
}

class _SatisfyingMissionButtonState extends State<SatisfyingMissionButton> {
  bool _pressed = false;

  static const _neonCyan = Color(0xFF00FFD1);
  static const _neonMagenta = Color(0xFFFF2D95);
  static const _darkCard = Color(0xFF12182A);

  void _fireTap() {
    HapticFeedback.selectionClick();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = widget.isCompleted ? Colors.greenAccent : _neonMagenta;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: _fireTap,
        child: Transform.translate(
          offset: Offset(0, _pressed ? 6.0 : 0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _darkCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isCompleted
                    ? Colors.greenAccent.withValues(alpha: 0.65)
                    : _neonCyan.withValues(alpha: 0.9),
                width: 0.5,
              ),
              boxShadow: _pressed
                  ? const <BoxShadow>[]
                  : <BoxShadow>[
                      BoxShadow(
                        color: accent.withValues(alpha: 0.45),
                        offset: const Offset(0, 6),
                        blurRadius: 14,
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        offset: const Offset(0, 6),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
            ),
            child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      _neonCyan.withValues(alpha: 0.35),
                      _neonMagenta.withValues(alpha: 0.25),
                    ],
                  ),
                ),
                child: Icon(
                  widget.isCompleted ? Icons.check_rounded : widget.icon,
                  color: widget.isCompleted ? Colors.greenAccent : scheme.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isCompleted
                          ? 'Terminé · +${widget.points} pts'
                          : '+${widget.points} XP · Appuie pour valider',
                      style: TextStyle(
                        color: scheme.primary.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                widget.isCompleted ? Icons.undo_rounded : Icons.bolt_rounded,
                color: widget.isCompleted ? Colors.orangeAccent : _neonMagenta,
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
