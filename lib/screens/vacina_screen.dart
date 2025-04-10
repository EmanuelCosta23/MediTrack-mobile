import 'package:flutter/material.dart';

class VacinaScreen extends StatefulWidget {
  const VacinaScreen({super.key});

  @override
  State<VacinaScreen> createState() => _VacinaScreenState();
}

class _VacinaScreenState extends State<VacinaScreen> {
  final List<String> _vacinas = [
    'Gripe',
    'BCG',
    'Hepatite A',
    'Hepatite B',
    'Penta (DTP/Hib/Hep. B)',
    'Pneumocócica 10 valente',
    'Vacina Inativada Poliomielite (VIP)',
    'Vacina Oral Poliomielite (VOP)',
    'Vacina Rotavírus Humano (VRH)',
    'Meningocócica C (conjugada)',
    'Febre amarela',
    'Tríplice viral',
    'Tetraviral',
    'DTP (tríplice bacteriana)',
    'Varicela',
    'HPV quadrivalente',
    'dT (dupla adulto)',
    'dTpa (DTP adulto)',
    'Menigocócica ACWY',
  ];

  String _searchQuery = '';
  List<String> _filteredVacinas = [];

  @override
  void initState() {
    super.initState();
    _filteredVacinas = _vacinas;
  }

  void _filterVacinas(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredVacinas = _vacinas;
      } else {
        _filteredVacinas = _vacinas
            .where((vacina) =>
                vacina.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vacinas'),
        backgroundColor: const Color(0xFF0080FF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar with autocomplete
            TextField(
              onChanged: _filterVacinas,
              decoration: InputDecoration(
                hintText: 'Buscar vacina',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF0080FF)),
              ),
            ),
            const SizedBox(height: 16),
            // List of vaccines
            Expanded(
              child: ListView.builder(
                itemCount: _filteredVacinas.length,
                itemBuilder: (context, index) {
                  return VaccineTile(name: _filteredVacinas[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VaccineTile extends StatelessWidget {
  final String name;

  const VaccineTile({super.key, required this.name});

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