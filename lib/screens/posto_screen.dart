import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../widgets/sidebar.dart';
import 'detalhe_posto.dart';
import 'home_screen.dart'; // Importar a tela home

class PostoScreen extends StatefulWidget {
  const PostoScreen({super.key});

  @override
  State<PostoScreen> createState() => _PostoScreenState();
}

class _PostoScreenState extends State<PostoScreen> {
  List<dynamic> _postos = [];
  List<dynamic> _postosFiltrados = [];
  bool _isLoading = true;
  String _erro = '';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _ordenarPorProximidade = true; // Por padrão, ordenamos por proximidade
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _carregarPostos();
  }

  Future<void> _carregarPostos() async {
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
                'Não foi possível exibir postos de saúde próximos. É necessário que a localização esteja ativada para este aplicativo.';
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
              'O serviço de localização está desativado. Por favor, ative-o nas configurações do seu dispositivo.';
          _isLoading = false;
        });
        return;
      }

      // Obter localização atual
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Buscar postos próximos
      final postos = await ApiService.getPostosProximos(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        20.0, // Raio de 20km para pegar mais postos
      );

      setState(() {
        _postos = postos;
        _aplicarFiltros();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _erro =
            'Ocorreu um erro ao buscar postos. Verifique suas configurações de localização e tente novamente.';
        _isLoading = false;
      });
    }
  }

  void _aplicarFiltros() {
    // Filtrar pelo termo de pesquisa
    List<dynamic> postosFiltrados =
        _postos.where((posto) {
          final nome = posto['nome'] ?? '';
          final endereco =
              '${posto['rua'] ?? ''}, ${posto['numero'] ?? ''}, ${posto['bairro'] ?? ''}';
          return nome.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              endereco.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

    // Ordenar pela escolha do usuário
    if (_ordenarPorProximidade) {
      // Já vem ordenado por proximidade da API, mas reforçamos a ordenação
      postosFiltrados.sort((a, b) {
        double distanciaA = a['distancia'] ?? 0.0;
        double distanciaB = b['distancia'] ?? 0.0;
        return distanciaA.compareTo(distanciaB);
      });
    } else {
      // Ordenar alfabeticamente pelo nome
      postosFiltrados.sort((a, b) {
        String nomeA = a['nome'] ?? '';
        String nomeB = b['nome'] ?? '';
        return nomeA.toLowerCase().compareTo(nomeB.toLowerCase());
      });
    }

    setState(() {
      _postosFiltrados = postosFiltrados;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Postos de Saúde'),
        backgroundColor: const Color(0xFF0080FF),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          // Botão Home
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              // Navegação para a home resetando a pilha de navegação
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false, // Remove todas as rotas anteriores
              );
            },
          ),
        ],
      ),
      drawer: const Sidebar(),
      body: Column(
        children: [
          // Barra de pesquisa
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pesquisar postos...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF0080FF)),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: Color(0xFF0080FF),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                            _aplicarFiltros();
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFF0080FF)),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
                _aplicarFiltros();
              },
            ),
          ),

          // Opções de filtro
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Text('Ordenar por:'),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('Proximidade'),
                  selected: _ordenarPorProximidade,
                  onSelected: (selected) {
                    setState(() {
                      _ordenarPorProximidade = true;
                    });
                    _aplicarFiltros();
                  },
                  selectedColor: const Color(0xFF0080FF).withOpacity(0.3),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('Nome'),
                  selected: !_ordenarPorProximidade,
                  onSelected: (selected) {
                    setState(() {
                      _ordenarPorProximidade = false;
                    });
                    _aplicarFiltros();
                  },
                  selectedColor: const Color(0xFF0080FF).withOpacity(0.3),
                ),
              ],
            ),
          ),

          // Lista de postos
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0080FF),
                      ),
                    )
                    : _erro.isNotEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              _erro,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _carregarPostos,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0080FF),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    )
                    : _postosFiltrados.isEmpty
                    ? const Center(child: Text('Nenhum posto encontrado'))
                    : RefreshIndicator(
                      onRefresh: _carregarPostos,
                      color: const Color(0xFF0080FF),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _postosFiltrados.length,
                        itemBuilder: (context, index) {
                          final posto = _postosFiltrados[index];
                          final nome = posto['nome'] ?? 'Nome indisponível';
                          final rua = posto['rua'] ?? '';
                          final numero = posto['numero'] ?? '';
                          final bairro = posto['bairro'] ?? '';
                          final endereco = '$rua, $numero - $bairro';
                          final distancia = posto['distancia'] ?? 0.0;
                          final distanciaFormatada =
                              '${distancia.toStringAsFixed(1)} km';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16.0),
                            elevation: 4,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => DetalhePosto(
                                          nome: nome,
                                          endereco: endereco,
                                          id: posto['id'] ?? '',
                                        ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nome,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      endereco,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          size: 16,
                                          color: Color(0xFF0080FF),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          distanciaFormatada,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[800],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Indicador de que é clicável
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Toque para ver detalhes',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.info_outline,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
