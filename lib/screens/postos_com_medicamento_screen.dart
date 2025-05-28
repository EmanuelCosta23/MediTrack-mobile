import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../widgets/sidebar.dart';
import 'detalhe_posto.dart';
import 'home_screen.dart';
import 'mapa_posto_screen.dart';

class PostosComMedicamentoScreen extends StatefulWidget {
  final String medicamentoId;
  final String nomeMedicamento;

  const PostosComMedicamentoScreen({
    super.key,
    required this.medicamentoId,
    required this.nomeMedicamento,
  });

  @override
  State<PostosComMedicamentoScreen> createState() =>
      _PostosComMedicamentoScreenState();
}

class _PostosComMedicamentoScreenState
    extends State<PostosComMedicamentoScreen> {
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
      // Buscar postos que têm o medicamento disponível
      final postos = await ApiService.getPostosComMedicamentoDisponivel(
        widget.medicamentoId,
      );

      // Verificar a estrutura dos dados para debug
      if (postos.isNotEmpty) {
        debugPrint('Estrutura do primeiro posto: ${postos[0].keys.toList()}');
        debugPrint(
          'ID do primeiro posto: ${postos[0]['id'] ?? postos[0]['postoId'] ?? postos[0]['idPosto'] ?? 'ID não encontrado'}',
        );
        // Se for um posto da estrutura de 'postos'
        if (postos[0]['nome'] == null && postos[0]['nomePosto'] != null) {
          debugPrint('Usando estrutura alternativa de nomePosto');
        }
      }

      // Tenta obter localização se disponível (para ordenação e cálculo de distância)
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

        if (permission != LocationPermission.denied &&
            permission != LocationPermission.deniedForever &&
            serviceEnabled) {
          _currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
        }
      } catch (e) {
        // Se não conseguir obter localização, apenas continua sem ordenar por proximidade
        debugPrint('Não foi possível obter localização: $e');
      }

      // Para cada posto na lista, buscar detalhes completos
      List<Map<String, dynamic>> postosCompletos = [];
      for (var posto in postos) {
        try {
          // Identificar o ID do posto
          String? postoId;
          if (posto['id'] != null && posto['id'].toString().isNotEmpty) {
            postoId = posto['id'].toString();
          } else if (posto['postoId'] != null &&
              posto['postoId'].toString().isNotEmpty) {
            postoId = posto['postoId'].toString();
          } else if (posto['idPosto'] != null &&
              posto['idPosto'].toString().isNotEmpty) {
            postoId = posto['idPosto'].toString();
          }

          // Se encontrou um ID, buscar detalhes completos
          if (postoId != null) {
            debugPrint('Buscando detalhes completos para posto ID: $postoId');
            final postoCompleto = await ApiService.getPostoDetailById(postoId);

            // Mesclar dados originais com dados completos
            Map<String, dynamic> postoMesclado = {...posto};

            // Adicionar campos importantes da resposta completa
            if (postoCompleto['latitude'] != null)
              postoMesclado['latitude'] = postoCompleto['latitude'];
            if (postoCompleto['longitude'] != null)
              postoMesclado['longitude'] = postoCompleto['longitude'];
            if (postoCompleto['nome'] != null)
              postoMesclado['nome'] = postoCompleto['nome'];
            if (postoCompleto['rua'] != null)
              postoMesclado['rua'] = postoCompleto['rua'];
            if (postoCompleto['numero'] != null)
              postoMesclado['numero'] = postoCompleto['numero'];
            if (postoCompleto['bairro'] != null)
              postoMesclado['bairro'] = postoCompleto['bairro'];
            if (postoCompleto['telefone'] != null)
              postoMesclado['telefone'] = postoCompleto['telefone'];

            // Calcular distância se a posição do usuário estiver disponível
            if (_currentPosition != null &&
                postoCompleto['latitude'] != null &&
                postoCompleto['longitude'] != null) {
              final double? lat = double.tryParse(
                postoCompleto['latitude'].toString(),
              );
              final double? lng = double.tryParse(
                postoCompleto['longitude'].toString(),
              );

              if (lat != null && lng != null) {
                final distanceInMeters = Geolocator.distanceBetween(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                  lat,
                  lng,
                );

                // Converter para km e arredondar para 1 casa decimal
                final distanceInKm = distanceInMeters / 1000;
                postoMesclado['distancia'] = distanceInKm;
                debugPrint(
                  'Distância calculada para ${postoMesclado['nome'] ?? postoMesclado['nomePosto']}: ${distanceInKm.toStringAsFixed(1)} km',
                );
              }
            }

            postosCompletos.add(postoMesclado);
          } else {
            // Se não encontrou ID, adicionar o posto original
            postosCompletos.add(posto);
          }
        } catch (e) {
          debugPrint('Erro ao buscar detalhes completos do posto: $e');
          // Em caso de erro, manter o posto original
          postosCompletos.add(posto);
        }
      }

      setState(() {
        _postos = postosCompletos;
        _aplicarFiltros();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _erro =
            'Não foi possível carregar os postos com este medicamento. Tente novamente mais tarde.';
        _isLoading = false;
      });
      debugPrint('Erro ao carregar postos com medicamento: $e');
    }
  }

  double? _parseCoordinate(dynamic value) {
    if (value == null) return null;

    if (value is double) {
      return value;
    } else if (value is int) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value);
    } else {
      return double.tryParse(value.toString());
    }
  }

  // Método para extrair coordenadas de um objeto de posto, verificando todas as possíveis chaves
  Map<String, double?> _extrairCoordenadas(Map<String, dynamic> posto) {
    double? lat;
    double? lng;

    // Lista de possíveis chaves para latitude e longitude
    final possiveisChavesFmt = [
      {'lat': 'latitude', 'lng': 'longitude'},
      {'lat': 'latitudePosto', 'lng': 'longitudePosto'},
      {'lat': 'lat', 'lng': 'lng'},
      {'lat': 'latitudeposto', 'lng': 'longitudeposto'},
      {'lat': 'lat_posto', 'lng': 'lng_posto'},
    ];

    // Tentar cada formato
    for (var chaves in possiveisChavesFmt) {
      if (posto[chaves['lat']] != null && posto[chaves['lng']] != null) {
        lat = _parseCoordinate(posto[chaves['lat']]);
        lng = _parseCoordinate(posto[chaves['lng']]);
        debugPrint(
          'Coordenadas encontradas em ${chaves['lat']}/${chaves['lng']}: $lat, $lng',
        );
        if (lat != null && lng != null) break;
      }
    }

    return {'lat': lat, 'lng': lng};
  }

  void _aplicarFiltros() {
    // Filtrar pelo termo de pesquisa
    List<dynamic> postosFiltrados =
        _postos.where((posto) {
          final nome = posto['nomePosto'] ?? posto['nome'] ?? '';
          final endereco =
              '${posto['ruaPosto'] ?? posto['rua'] ?? ''}, '
              '${posto['numeroPosto'] ?? posto['numero'] ?? ''}, '
              '${posto['bairroPosto'] ?? posto['bairro'] ?? ''}';

          return nome.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              endereco.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

    // Ordenar pela escolha do usuário
    if (_ordenarPorProximidade && _currentPosition != null) {
      // Ordenar por proximidade se tiver localização
      postosFiltrados.sort((a, b) {
        double distanciaA = a['distancia'] ?? 0.0;
        double distanciaB = b['distancia'] ?? 0.0;
        return distanciaA.compareTo(distanciaB);
      });
    } else {
      // Ordenar alfabeticamente pelo nome
      postosFiltrados.sort((a, b) {
        String nomeA = a['nomePosto'] ?? a['nome'] ?? '';
        String nomeB = b['nomePosto'] ?? b['nome'] ?? '';
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
        title: Text('Postos com ${widget.nomeMedicamento}'),
        // backgroundColor: const Color(0xFF0080FF),
        backgroundColor: const Color(0xFF40BFFF),
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
      body: Column(
        children: [
          // Barra de pesquisa
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pesquisar postos...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF40BFFF)),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: Color(0xFF40BFFF),
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
                  borderSide: const BorderSide(color: Color(0xFF40BFFF)),
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
                  selectedColor: const Color(0xFF40BFFF).withOpacity(0.3),
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
                  selectedColor: const Color(0xFF40BFFF).withOpacity(0.3),
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
                        color: Color(0xFF40BFFF),
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
                              backgroundColor: const Color(0xFF40BFFF),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    )
                    : _postosFiltrados.isEmpty
                    ? Center(
                      child: Text(
                        'Nenhum posto encontrado com ${widget.nomeMedicamento} disponível',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _carregarPostos,
                      color: const Color(0xFF40BFFF),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _postosFiltrados.length,
                        itemBuilder: (context, index) {
                          final posto = _postosFiltrados[index];
                          final nome =
                              posto['nomePosto'] ??
                              posto['nome'] ??
                              'Nome indisponível';
                          final rua = posto['ruaPosto'] ?? posto['rua'] ?? '';
                          final numero =
                              posto['numeroPosto'] ?? posto['numero'] ?? '';
                          final bairro =
                              posto['bairroPosto'] ?? posto['bairro'] ?? '';
                          final endereco = '$rua, $numero - $bairro';

                          // Distância (se disponível)
                          String distanciaText = '';
                          if (posto['distancia'] != null) {
                            final distancia = posto['distancia'] as double;
                            distanciaText =
                                '${distancia.toStringAsFixed(1)} km';
                          }

                          // Garantir que pegamos o ID corretamente
                          // Verificar todas as possíveis chaves onde o ID pode estar
                          String? postoId;

                          // Primeiro, tenta encontrar o ID diretamente no objeto
                          if (posto['id'] != null &&
                              posto['id'].toString().isNotEmpty) {
                            postoId = posto['id'].toString();
                          }
                          // Casos alternativos de formatação
                          else if (posto['postoId'] != null &&
                              posto['postoId'].toString().isNotEmpty) {
                            postoId = posto['postoId'].toString();
                          } else if (posto['idPosto'] != null &&
                              posto['idPosto'].toString().isNotEmpty) {
                            postoId = posto['idPosto'].toString();
                          }
                          // Se não encontrou o ID, tenta extrair de outros campos
                          else if (posto['medicamentos'] != null &&
                              (posto['medicamentos'] as List).isNotEmpty) {
                            // Tenta extrair o ID do posto a partir do primeiro medicamento
                            final firstMed = posto['medicamentos'][0];
                            if (firstMed['postoId'] != null) {
                              postoId = firstMed['postoId'].toString();
                            }
                          }

                          // Se ainda não encontramos um ID, usamos o nome do posto
                          if (postoId == null || postoId.isEmpty) {
                            debugPrint(
                              'ID do posto não encontrado, usando nome do posto como identificador: $nome',
                            );
                            postoId =
                                nome; // Usar nome como identificador quando não tem ID
                          } else {
                            debugPrint('ID do posto encontrado: $postoId');
                          }

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
                                          id: postoId!,
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
                                    // Sempre exibir a Row da distância, mesmo se vazia (para manter o layout consistente)
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          size: 16,
                                          color: Color(0xFF40BFFF),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          distanciaText.isNotEmpty
                                              ? distanciaText
                                              : "Distância não disponível",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[800],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Indicador de que é clicável (igual à tela de remédios)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
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
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            // Obter coordenadas para mostrar no mapa
                                            double? lat;
                                            double? lng;

                                            // Verificar todas as possíveis chaves de coordenadas
                                            final coordenadas =
                                                _extrairCoordenadas(posto);
                                            lat = coordenadas['lat'];
                                            lng = coordenadas['lng'];

                                            if (lat != null && lng != null) {
                                              // Navegar para a tela de mapa
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (
                                                        context,
                                                      ) => MapaPostoScreen(
                                                        nome: nome,
                                                        endereco: endereco,
                                                        latitude: lat,
                                                        longitude: lng,
                                                        distancia:
                                                            posto['distancia'],
                                                      ),
                                                ),
                                              );
                                            } else {
                                              // Mostrar mensagem se não tiver coordenadas
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Não foi possível obter a localização deste posto',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.map_outlined,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                          label: const Text(
                                            'Ver no Mapa',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF40BFFF,
                                            ),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            minimumSize: const Size(30, 24),
                                          ),
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
