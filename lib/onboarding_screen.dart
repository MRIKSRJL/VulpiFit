import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dashboard_screen.dart';
import 'services/mission_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _bg = Color(0xFF060814);
  static const _card = Color(0xFF12182A);
  static const _cyan = Color(0xFF00FFD1);
  static const _magenta = Color(0xFFFF2D95);
  static const _appBar = Color(0xFF0F1628);

  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _injuriesController = TextEditingController();

  final List<String> _selectedGoals = [];

  final List<String> _availableGoals = [
    'Perte de gras',
    'Prise de muscle',
    'Force pure (Powerlifting)',
    'Endurance / Cardio',
    'Souplesse / Mobilité',
    'Athlète Hybride',
    'Remise en forme douce',
  ];

  bool _isLoading = false;
  bool _ctaPressed = false;

  InputDecoration _fieldDecoration({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    final borderColor = _cyan.withValues(alpha: 0.45);
    return InputDecoration(
      filled: true,
      fillColor: _card,
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
      labelStyle: TextStyle(color: _cyan.withValues(alpha: 0.95)),
      floatingLabelStyle: const TextStyle(color: _cyan),
      prefixIcon: icon != null ? Icon(icon, color: _magenta.withValues(alpha: 0.95)) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _cyan, width: 1.2),
      ),
    );
  }

  Future<void> _soumettreFormulaire() async {
    if (_weightController.text.isEmpty || _heightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Le poids et la taille sont obligatoires.'),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedGoals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Choisis au moins un objectif.'),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _ctaPressed = false;
    });

    final weight = double.tryParse(_weightController.text) ?? 70.0;
    final height = int.tryParse(_heightController.text) ?? 170;
    final injuries = _injuriesController.text;
    final finalGoals = _selectedGoals.join(', ');

    final success =
        await MissionService.updateOnboarding(weight, height, injuries, finalGoals);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erreur lors de l’enregistrement. Réessaie.'),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _injuriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Faisons connaissance !',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _appBar,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pour que ton coach IA te génère des missions adaptées, parle-nous un peu de toi :',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    cursorColor: _cyan,
                    decoration: _fieldDecoration(
                      label: 'Poids (kg)',
                      icon: Icons.monitor_weight_outlined,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    cursorColor: _cyan,
                    decoration: _fieldDecoration(
                      label: 'Taille (cm)',
                      icon: Icons.height,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            Text(
              'Quels sont tes objectifs ? (plusieurs choix possibles)',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.88),
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableGoals.map((goal) {
                final isSelected = _selectedGoals.contains(goal);
                return FilterChip(
                  label: Text(goal),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.88),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                  selected: isSelected,
                  selectedColor: _magenta.withValues(alpha: 0.55),
                  backgroundColor: _card,
                  checkmarkColor: Colors.white,
                  side: BorderSide(
                    color: isSelected ? _magenta : _cyan.withValues(alpha: 0.35),
                    width: isSelected ? 1.2 : 0.5,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedGoals.add(goal);
                      } else {
                        _selectedGoals.remove(goal);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            TextField(
              controller: _injuriesController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              cursorColor: _cyan,
              decoration: _fieldDecoration(
                label: 'Blessures ou douleurs ? (optionnel)',
                hint: 'Ex. : genou droit, dos…',
                icon: Icons.healing_outlined,
              ),
            ),
            const SizedBox(height: 36),

            _NeonSubmitButton(
              label: "C'EST PARTI ! 🚀",
              loading: _isLoading,
              pressed: _ctaPressed,
              onTapDown: () => setState(() => _ctaPressed = true),
              onTapUp: () => setState(() => _ctaPressed = false),
              onTapCancel: () => setState(() => _ctaPressed = false),
              onPressed: _isLoading ? null : _soumettreFormulaire,
            ),
          ],
        ),
      ),
    );
  }
}

class _NeonSubmitButton extends StatelessWidget {
  const _NeonSubmitButton({
    required this.label,
    required this.loading,
    required this.pressed,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final bool pressed;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;
  final VoidCallback? onPressed;

  static const _cyan = Color(0xFF00FFD1);
  static const _magenta = Color(0xFFFF2D95);
  static const _dark = Color(0xFF12182A);

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => onTapDown() : null,
      onTapUp: enabled ? (_) => onTapUp() : null,
      onTapCancel: enabled ? onTapCancel : null,
      onTap: enabled
          ? () {
              HapticFeedback.selectionClick();
              onPressed!();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, pressed ? 6.0 : 0, 0),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _dark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cyan.withValues(alpha: 0.85), width: 0.5),
          boxShadow: pressed
              ? const <BoxShadow>[]
              : <BoxShadow>[
                  BoxShadow(
                    color: _magenta.withValues(alpha: 0.4),
                    offset: const Offset(0, 6),
                    blurRadius: 14,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    offset: const Offset(0, 6),
                    blurRadius: 8,
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: _cyan,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: enabled ? Colors.white : Colors.white38,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}
