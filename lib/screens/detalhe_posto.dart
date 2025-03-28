import 'package:flutter/material.dart';

class DetalhePosto extends StatelessWidget {
  final String nome;
  final String endereco;

  const DetalhePosto({super.key, required this.nome, required this.endereco});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top blue box
          Container(
            color: const Color(0xFF0080FF),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 48), // Placeholder for spacing
                    IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.red),
                      onPressed: () {
                        // Add your favorite functionality here
                      },
                    ),
                  ],
                ),
                Text(
                  nome,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  endereco,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Gray box for operating hours
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Horário de funcionamento:',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildOperatingHours(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Additional details section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detalhes adicionais:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildAdditionalDetails(),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Button to search for medications
          Center(
            child: ElevatedButton(
              onPressed: () {
                // Add your search functionality here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0080FF),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text(
                'Pesquisar remédios',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatingHours() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Segunda - feira: 08:00 - 17:00'),
        Text('Terça - feira: 08:00 - 17:00'),
        Text('Quarta - feira: 08:00 - 17:00'),
        Text('Quinta - feira: 08:00 - 17:00'),
        Text('Sexta - feira: 08:00 - 17:00'),
        Text('Sábado: 08:00 - 12:00'),
      ],
    );
  }

  Widget _buildAdditionalDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Telefone: (85) 3452-6377'),
        Text('Linhas de ônibus: 16; 51; 55; 92; 101; 120; 130; 132; 711; 725'),
      ],
    );
  }
} 