import 'package:flutter/material.dart';
import 'remedio_screen.dart'; // Import the RemedioScreen

class DetalhePosto extends StatelessWidget {
  final String nome;
  final String endereco;

  const DetalhePosto({super.key, required this.nome, required this.endereco});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // Centraliza no eixo horizontal
        children: [
          // Top blue box
          Container(
            width: double.infinity, // Garante que o container ocupe toda a largura
            color: const Color(0xFF0080FF),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                      icon: const Icon(Icons.favorite, color: Colors.pink),
                      onPressed: () {
                        // Add your favorite functionality here
                      },
                    ),
                  ],
                ),
                Center(
                  child: Text(
                    nome,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    endereco,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Horário de funcionamento:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Detalhes adicionais:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                _buildAdditionalDetails(),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Button to go to the medications screen
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RemedioScreen()),
                );
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: const [
        Text('Segunda - feira: 08:00 - 17:00', textAlign: TextAlign.center),
        Text('Terça - feira: 08:00 - 17:00', textAlign: TextAlign.center),
        Text('Quarta - feira: 08:00 - 17:00', textAlign: TextAlign.center),
        Text('Quinta - feira: 08:00 - 17:00', textAlign: TextAlign.center),
        Text('Sexta - feira: 08:00 - 17:00', textAlign: TextAlign.center),
        Text('Sábado: 08:00 - 12:00', textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildAdditionalDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: const [
        Text('Telefone: (85) 3452-6377', textAlign: TextAlign.center),
        Text('Linhas de ônibus: 16; 51; 55; 92; 101; 120; 130; 132; 711; 725', textAlign: TextAlign.center),
      ],
    );
  }
}
