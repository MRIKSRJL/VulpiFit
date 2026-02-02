import 'package:flutter/material.dart';

class StepsScreen extends StatelessWidget {
  const StepsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mission Pas 👣'), backgroundColor: Colors.purple),
      body: const Center(child: Text('Compteur de pas ici')),
    );
  }
}