import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import 'detalhe_posto.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Autenticação mantida mas não exibida visualmente
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MediTrack'),
        backgroundColor: const Color(0xFF0080FF),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      drawer: const Sidebar(),
      body: Container(
        color: const Color(0xFF0080FF),
        height: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Postos de Saúde',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPostoCard(
                    context,
                    'Posto de Saúde Central',
                    'Rua Principal, 123',
                  ),
                  _buildPostoCard(
                    context,
                    'UPA Jardim América',
                    'Av. das Flores, 456',
                  ),
                  _buildPostoCard(
                    context,
                    'Centro de Saúde Familiar',
                    'Rua dos Ipês, 789',
                  ),
                  _buildPostoCard(
                    context,
                    'Hospital Municipal',
                    'Av. Saúde, 1010',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostoCard(BuildContext context, String nome, String endereco) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.local_hospital,
              color: Color(0xFF0080FF),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              nome,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              endereco,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Center(
              child: SizedBox(
                height: 28,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                DetalhePosto(nome: nome, endereco: endereco),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF0080FF),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Ver detalhes',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
