import 'package:flutter/material.dart';

class RemedioScreen extends StatefulWidget {
  const RemedioScreen({super.key});

  @override
  State<RemedioScreen> createState() => _RemedioScreenState();
}

class _RemedioScreenState extends State<RemedioScreen> {
  final List<String> medicamentos = [
    'Amoxicilina',
    'Dipirona',
    'Ibuprofeno',
    'Paracetamol',
    'Cetirizina',
    'Omeprazol',
    'Ranitidina',
    'Losartana',
  ];

  List<String> filteredMedicamentos = [];

  @override
  void initState() {
    super.initState();
    filteredMedicamentos = medicamentos; // Inicialmente exibe todos os medicamentos
  }

  void _filterMedicamentos(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredMedicamentos = medicamentos;
      } else {
        filteredMedicamentos = medicamentos
            .where((medicamento) =>
                medicamento.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

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
              onChanged: _filterMedicamentos,
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
            // List of filtered medications
            Expanded(
              child: ListView.builder(
                itemCount: filteredMedicamentos.length,
                itemBuilder: (context, index) {
                  return MedicationTile(name: filteredMedicamentos[index]);
                },
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