import 'package:flutter/material.dart';

class RemedioScreen extends StatelessWidget {
  const RemedioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remédios'),
        backgroundColor: const Color(0xFF0080FF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Buscar remédio',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // List of medications
            Expanded(
              child: ListView(
                children: const [
                  MedicationTile(name: 'Amoxicilina'),
                  MedicationTile(name: 'Dipirona'),
                  MedicationTile(name: 'Ibuprofeno'),
                  MedicationTile(name: 'Paracetamol'),
                  MedicationTile(name: 'Cetirizina'),
                  MedicationTile(name: 'Omeprazol'),
                  MedicationTile(name: 'Ranitidina'),
                  MedicationTile(name: 'Losartana'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MedicationTile extends StatelessWidget {
  final String name;

  const MedicationTile({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(name),
        tileColor: const Color(0xFF0080FF),
        textColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
} 