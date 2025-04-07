import 'package:flutter/material.dart';
import 'remedio_screen.dart'; // Import the RemedioScreen

class DetalhePosto extends StatelessWidget {
  final String nome;
  final String endereco;

  const DetalhePosto({super.key, required this.nome, required this.endereco});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          nome,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0080FF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              nome,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              endereco,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Operating hours section
            Text(
              'Horário de funcionamento:',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            _buildOperatingHours(),
            const SizedBox(height: 16),
            // Additional details section
            _buildAdditionalDetails(),
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
