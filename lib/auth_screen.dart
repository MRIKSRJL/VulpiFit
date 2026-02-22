import 'package:flutter/material.dart';
import 'main.dart'; 
import 'services/mission_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _pseudoController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLogin = true; 

  void _submit() async {
    String pseudo = _pseudoController.text;
    String pass = _passController.text;

    if (pseudo.isEmpty || pass.isEmpty) return;

    bool success;
    if (_isLogin) {
      success = await MissionService.login(pseudo, pass);
    } else {
      success = await MissionService.register(pseudo, pass);
    }

    if (!mounted) return;

    if (success) {
      // On redirige vers main.dart (qui gère le Dashboard)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else {
      // 👇 LE MESSAGE INTELLIGENT EST ICI
      String messageErreur = _isLogin 
          ? "Échec ! Vérifie tes identifiants. 🦊" 
          : "Ce pseudo est déjà pris ! Choisis-en un autre. 🐾";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(messageErreur),
          backgroundColor: Colors.red.shade400, // Un peu de rouge pour l'erreur
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange,
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(20),
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.fitness_center, size: 60, color: Colors.orange),
                const SizedBox(height: 10),
                Text(
                  _isLogin ? "Bon retour ! 🦊" : "Rejoins la meute ! 🐾",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _pseudoController,
                  decoration: const InputDecoration(labelText: "Pseudo", prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Mot de passe", prefixIcon: Icon(Icons.lock)),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: Text(_isLogin ? "SE CONNECTER" : "CRÉER UN COMPTE"),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                    });
                  },
                  child: Text(_isLogin ? "Pas de compte ? Créer un compte" : "Déjà un compte ? Se connecter"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}