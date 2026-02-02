import 'package:flutter/material.dart';

class PhotoScreen extends StatelessWidget {
  const PhotoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mission Repas 📸'), backgroundColor: Colors.green),
      body: const Center(child: Text('Caméra ici')),
    );
  }
}