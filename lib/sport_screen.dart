import 'package:flutter/material.dart';

class SportScreen extends StatefulWidget {
  const SportScreen({super.key});

  @override
  State<SportScreen> createState() => _SportScreenState();
}

class _SportScreenState extends State<SportScreen> {
  // 1. LA MÉMOIRE (Les Données)
  // Voici la liste de vos exercices.
  // "isDone" permet de savoir si la case est cochée ou non.
  final List<Map<String, dynamic>> exercises = [
    {"name": "10 Pompes", "isDone": false},
    {"name": "20 Squats", "isDone": false},
    {"name": "30 sec Planche", "isDone": false},
    {"name": "15 Jumping Jacks", "isDone": false},
    {"name": "10 Fentes", "isDone": false},
  ];

  // 2. L'ACTION
  // Cette fonction est appelée quand on tape sur une case
  void toggleExercise(int index) {
    setState(() {
      // On inverse la valeur (Vrai devient Faux, Faux devient Vrai)
      exercises[index]['isDone'] = !exercises[index]['isDone'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mission Sport 🏋️'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "Objectif du jour",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Complétez tous les exercices pour valider la mission !",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // 3. LA LISTE DYNAMIQUE
            Expanded(
              child: ListView.separated(
                itemCount: exercises.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 15),
                itemBuilder: (context, index) {
                  // On récupère l'exercice actuel
                  final exercise = exercises[index];
                  final isDone = exercise['isDone'] as bool;

                  return InkWell(
                    onTap: () => toggleExercise(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300), // Animation fluide
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        // SI c'est fait = VERT, SINON = GRIS CLAIR
                        color: isDone ? Colors.green : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(15),
                        border: isDone 
                            ? Border.all(color: Colors.green, width: 2)
                            : Border.all(color: Colors.transparent),
                      ),
                      child: Row(
                        children: [
                          // L'icône change aussi
                          Icon(
                            isDone ? Icons.check_circle : Icons.circle_outlined,
                            color: isDone ? Colors.white : Colors.grey,
                            size: 30,
                          ),
                          const SizedBox(width: 20),
                          Text(
                            exercise['name'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              // SI c'est fait, le texte devient blanc et barré
                              color: isDone ? Colors.white : Colors.black87,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}