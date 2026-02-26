import 'package:flutter/material.dart';
import 'services/mission_service.dart';
import 'main.dart'; // Pour rediriger vers le DashboardScreen

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _injuriesController = TextEditingController();
  
  // 🔄 NOUVEAU : Une liste pour stocker PLUSIEURS objectifs
  final List<String> _selectedGoals = [];
  
  // Les options d'objectifs plus détaillées
  final List<String> _availableGoals = [
    'Perte de gras',
    'Prise de muscle',
    'Force pure (Powerlifting)',
    'Endurance / Cardio',
    'Souplesse / Mobilité',
    'Athlète Hybride',
    'Remise en forme douce'
  ];

  bool _isLoading = false;

  void _soumettreFormulaire() async {
    if (_weightController.text.isEmpty || _heightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Le poids et la taille sont obligatoires ! 🦊"), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_selectedGoals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Choisis au moins un objectif ! 🎯"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    double weight = double.tryParse(_weightController.text) ?? 70.0;
    int height = int.tryParse(_heightController.text) ?? 170;
    String injuries = _injuriesController.text;
    
    // 🔗 On relie tous les objectifs choisis avec une virgule pour l'IA
    String finalGoals = _selectedGoals.join(', ');

    // On envoie à l'API
    bool success = await MissionService.updateOnboarding(weight, height, injuries, finalGoals);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de l'enregistrement. Réessaie !"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Faisons connaissance !"),
        backgroundColor: Colors.orange,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Pour que ton coach IA te génère des missions parfaites, parle-nous un peu de toi :",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),

            // -- POIDS ET TAILLE --
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Poids (kg)",
                      prefixIcon: Icon(Icons.monitor_weight, color: Colors.orange),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Taille (cm)",
                      prefixIcon: Icon(Icons.height, color: Colors.orange),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // -- OBJECTIFS MULTIPLES (NOUVEAU DESIGN) --
            const Text("Quels sont tes objectifs ? (Plusieurs choix possibles)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            
            Wrap(
              spacing: 8.0, // Espace horizontal entre les puces
              runSpacing: 4.0, // Espace vertical
              children: _availableGoals.map((goal) {
                bool isSelected = _selectedGoals.contains(goal);
                return FilterChip(
                  label: Text(goal),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  selected: isSelected,
                  selectedColor: Colors.orange,
                  checkmarkColor: Colors.white,
                  backgroundColor: Colors.white,
                  shape: StadiumBorder(side: BorderSide(color: isSelected ? Colors.orange : Colors.grey.shade300)),
                  onSelected: (bool selected) {
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
            
            const SizedBox(height: 25),

            // -- BLESSURES --
            TextField(
              controller: _injuriesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Blessures ou douleurs ? (Optionnel)",
                hintText: "Ex: Douleur au genou droit, scoliose...",
                prefixIcon: Icon(Icons.healing, color: Colors.orange),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 40),

            // -- BOUTON VALIDER --
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _soumettreFormulaire,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("C'EST PARTI ! 🚀", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}