import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/sidebar.dart';
import 'detalhe_posto.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _postos = [];
  bool _isLoading = true;
  String _erro = '';

  @override
  void initState() {
    super.initState();
    _carregarPostosProximos();
  }

  Future<void> _carregarPostosProximos() async {
    setState(() {
      _isLoading = true;
      _erro = '';
    });

    try {
      // Verificar e solicitar permissão de localização
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          setState(() {
            _erro =
                'Não foi possível exibir postos de saúde próximos. É necessário que a localização esteja ativada para este aplicativo. Verifique suas configurações de localização.';
            _isLoading = false;
          });
          return;
        }
      }

      // Verificar se o serviço de localização está ativado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _erro =
              'O serviço de localização está desativado. Por favor, ative-o nas configurações do seu dispositivo para visualizar os postos próximos.';
          _isLoading = false;
        });
        return;
      }

      // Obter localização atual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Buscar postos próximos
      final postos = await ApiService.getPostosProximos(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _postos = postos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _erro =
            'Ocorreu um erro ao buscar postos próximos. Verifique suas configurações de localização e tente novamente.';
        _isLoading = false;
      });
    }
  }

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
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                : _erro.isNotEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Erro: $_erro',
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _carregarPostosProximos,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0080FF),
                        ),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
                : RefreshIndicator(
                  onRefresh: _carregarPostosProximos,
                  color: const Color(0xFF0080FF),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            'Postos de Saúde Próximos',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio:
                                    0.75, // Ajuste para o card com informação adicional
                              ),
                          itemCount: _postos.length > 6 ? 6 : _postos.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final posto = _postos[index];
                            final distancia = posto['distancia'] ?? 0.0;
                            final distanciaFormatada =
                                '${distancia.toStringAsFixed(1)} km';

                            return _buildPostoCard(
                              context,
                              posto['nome'] ?? 'Nome indisponível',
                              '${posto['rua'] ?? ''}, ${posto['numero'] ?? ''}, ${posto['bairro'] ?? ''}',
                              distanciaFormatada,
                              posto['id'] ?? '',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildPostoCard(
    BuildContext context,
    String nome,
    String endereco,
    String distancia,
    String id,
  ) {
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
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.grey[800], size: 14),
                const SizedBox(width: 2),
                Text(
                  distancia,
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Center(
              child: SizedBox(
                height: 28,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => DetalhePosto(
                              nome: nome,
                              endereco: endereco,
                              id: id,
                            ),
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
