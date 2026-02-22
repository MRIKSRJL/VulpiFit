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
  
  // L'objectif sélectionné par défaut
  String _selectedGoal = 'Perte de poids';
  
  // Les options de la liste déroulante
  final List<String> _goals = [
    'Perte de poids',
    'Prise de masse musculaire',
    'Remise en forme / Santé',
    'Performance sportive'
  ];

  bool _isLoading = false;

  void _soumettreFormulaire() async {
    // 1. On vérifie que les champs obligatoires sont remplis
    if (_weightController.text.isEmpty || _heightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Le poids et la taille sont obligatoires ! 🦊"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    double weight = double.tryParse(_weightController.text) ?? 70.0;
    int height = int.tryParse(_heightController.text) ?? 170;
    String injuries = _injuriesController.text;

    // 2. On envoie à l'API
    bool success = await MissionService.updateOnboarding(weight, height, injuries, _selectedGoal);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // 3. Si ça marche, direction le Dashboard !
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

            // -- OBJECTIF --
            const Text("Quel est ton objectif principal ?", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(5),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedGoal,
                  isExpanded: true,
                  icon: const Icon(Icons.flag, color: Colors.orange),
                  items: _goals.map((String goal) {
                    return DropdownMenuItem<String>(
                      value: goal,
                      child: Text(goal),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedGoal = newValue!;
                    });
                  },
                ),
              ),
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