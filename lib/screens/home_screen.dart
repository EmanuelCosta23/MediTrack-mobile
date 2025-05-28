import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/sidebar.dart';
import '../widgets/custom_logo.dart';
import 'detalhe_posto.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'dart:developer' as developer;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _postos = [];
  bool _isLoading = true;
  String _erro = '';
  Position? _userPosition;
  final LatLng _defaultLocation = const LatLng(
    -3.7480523,
    -38.5676128,
  ); // Fortaleza, CE

  @override
  void initState() {
    super.initState();
    // Primeiro tenta obter localização do emulador, depois fallback para o método padrão
    _obterLocalizacaoEmulador().then((localizacaoObtida) {
      if (!localizacaoObtida) {
        _carregarPostosProximos();
      }
    });
  }

  Future<void> _carregarPostosProximos() async {
    setState(() {
      _isLoading = true;
      _erro = '';
    });

    try {
      developer.log('==========================================');
      developer.log('HomeScreen: TENTANDO OBTER LOCALIZAÇÃO REAL');
      developer.log('==========================================');

      // Verificar e solicitar permissão de localização
      LocationPermission permission = await Geolocator.checkPermission();
      developer.log('HomeScreen: Permissão atual: $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        developer.log('HomeScreen: Permissão após solicitação: $permission');

        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          developer.log('==========================================');
          developer.log('HomeScreen: PERMISSÃO DE LOCALIZAÇÃO NEGADA!');
          developer.log('==========================================');
          setState(() {
            _erro =
                'Não foi possível exibir postos de saúde próximos. É necessário que a localização esteja ativada para este aplicativo. Verifique suas configurações de localização.';
            _isLoading = false;
          });

          // Tentar usar localização padrão
          _buscarComLocalizacaoPadrao();
          return;
        }
      }

      // Verificar se o serviço de localização está ativado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      developer.log(
        'HomeScreen: Serviço de localização ativado: $serviceEnabled',
      );

      if (!serviceEnabled) {
        developer.log('==========================================');
        developer.log('HomeScreen: SERVIÇO DE LOCALIZAÇÃO DESATIVADO!');
        developer.log('==========================================');
        setState(() {
          _erro =
              'O serviço de localização está desativado. Por favor, ative-o nas configurações do seu dispositivo para visualizar os postos próximos.';
          _isLoading = false;
        });

        // Tentar usar localização padrão
        _buscarComLocalizacaoPadrao();
        return;
      }

      // Obter localização atual - com várias tentativas
      try {
        developer.log(
          'HomeScreen: Tentando obter posição atual com alta precisão...',
        );
        try {
          _userPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 10),
          );
          developer.log('==========================================');
          developer.log(
            'HomeScreen: SUCESSO! Posição obtida com alta precisão!',
          );
          developer.log(
            'LAT: ${_userPosition?.latitude}, LONG: ${_userPosition?.longitude}',
          );
          developer.log('==========================================');
        } catch (e) {
          developer.log(
            'HomeScreen: FALHA ao obter posição com alta precisão: $e. Tentando com precisão menor...',
          );
          try {
            _userPosition = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium,
              timeLimit: const Duration(seconds: 8),
            );
            developer.log('==========================================');
            developer.log(
              'HomeScreen: SUCESSO! Posição obtida com precisão média!',
            );
            developer.log(
              'LAT: ${_userPosition?.latitude}, LONG: ${_userPosition?.longitude}',
            );
            developer.log('==========================================');
          } catch (e) {
            developer.log(
              'HomeScreen: FALHA ao obter posição com precisão média: $e. Tentando com última localização conhecida...',
            );
            try {
              _userPosition = await Geolocator.getLastKnownPosition();
              if (_userPosition != null) {
                developer.log('==========================================');
                developer.log(
                  'HomeScreen: SUCESSO! Última posição conhecida obtida!',
                );
                developer.log(
                  'LAT: ${_userPosition?.latitude}, LONG: ${_userPosition?.longitude}',
                );
                developer.log('==========================================');
              } else {
                developer.log('==========================================');
                developer.log(
                  'HomeScreen: FALHA! Não foi possível obter a última posição conhecida.',
                );
                developer.log('==========================================');
                throw Exception('Não foi possível obter a localização');
              }
            } catch (e) {
              developer.log('==========================================');
              developer.log(
                'HomeScreen: FALHA! Erro ao obter última posição conhecida: $e',
              );
              developer.log('==========================================');
              // Tentar usar localização padrão
              _buscarComLocalizacaoPadrao();
              return;
            }
          }
        }

        // Mostrar no console qual localização está sendo usada
        if (_userPosition != null) {
          developer.log('==========================================');
          developer.log('HomeScreen: USANDO LOCALIZAÇÃO REAL!');
          developer.log(
            'LAT: ${_userPosition!.latitude}, LONG: ${_userPosition!.longitude}',
          );
          developer.log('==========================================');

          // Buscar postos próximos usando a posição real
          final postos = await ApiService.getPostosProximos(
            _userPosition!.latitude,
            _userPosition!.longitude,
            10.0, // raio de 10km
          );
          developer.log('HomeScreen: Postos encontrados: ${postos.length}');

          setState(() {
            _postos = postos;
            _isLoading = false;
          });
        } else {
          throw Exception('Não foi possível obter a localização');
        }
      } catch (e) {
        developer.log('HomeScreen: Erro ao obter posição: $e');
        _buscarComLocalizacaoPadrao();
      }
    } catch (e) {
      developer.log('HomeScreen: Erro geral: $e');
      setState(() {
        _erro =
            'Ocorreu um erro ao buscar postos próximos. Verifique suas configurações de localização e tente novamente.';
        _isLoading = false;
      });

      // Tentar usar localização padrão
      _buscarComLocalizacaoPadrao();
    }
  }

  // Método para buscar com localização padrão quando falha em obter a localização real
  Future<void> _buscarComLocalizacaoPadrao() async {
    try {
      developer.log('==========================================');
      developer.log('HomeScreen: USANDO LOCALIZAÇÃO PADRÃO!');
      developer.log(
        'LAT: ${_defaultLocation.latitude}, LONG: ${_defaultLocation.longitude}',
      );
      developer.log('==========================================');

      // Buscar postos próximos usando a posição padrão
      final postos = await ApiService.getPostosProximos(
        _defaultLocation.latitude,
        _defaultLocation.longitude,
        10.0, // raio de 10km
      );
      developer.log(
        'HomeScreen: Postos encontrados com localização padrão: ${postos.length}',
      );

      setState(() {
        _postos = postos;
        _isLoading = false;
        // Adicionar uma mensagem ao erro para informar que está usando localização padrão
        if (_erro.isEmpty) {
          _erro =
              'Não foi possível obter sua localização atual. Mostrando postos próximos a uma localização padrão.';
        }
      });
    } catch (e) {
      developer.log('HomeScreen: Erro ao buscar com localização padrão: $e');
      setState(() {
        _erro =
            'Não foi possível buscar postos de saúde. Por favor, tente novamente mais tarde.';
        _isLoading = false;
      });
    }
  }

  // Método específico para obter localização no emulador
  Future<bool> _obterLocalizacaoEmulador() async {
    try {
      developer.log('==========================================');
      developer.log('HomeScreen: TENTANDO OBTER LOCALIZAÇÃO PARA EMULADOR');
      developer.log('==========================================');

      // Verificar permissões primeiro
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // Se não tem permissão, falha
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        developer.log('==========================================');
        developer.log('HomeScreen: PERMISSÃO DE LOCALIZAÇÃO NEGADA');
        developer.log('==========================================');
        return false;
      }

      // No emulador, às vezes precisamos forçar uma localização manualmente
      // Verificar se já existe uma posição simulada no emulador
      developer.log('HomeScreen: Tentando obter via stream (emulador)...');
      final List<Position> positions =
          await GeolocatorPlatform.instance
              .getPositionStream(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.best,
                  distanceFilter: 0,
                ),
              )
              .timeout(const Duration(seconds: 5))
              .take(1)
              .toList();

      if (positions.isNotEmpty) {
        _userPosition = positions.first;
        developer.log('==========================================');
        developer.log(
          'HomeScreen: SUCESSO NO EMULADOR: Posição obtida via stream!',
        );
        developer.log(
          'LAT: ${_userPosition!.latitude}, LONG: ${_userPosition!.longitude}',
        );
        developer.log('==========================================');

        setState(() {
          _isLoading = true;
        });

        // Buscar postos com esta posição
        final postos = await ApiService.getPostosProximos(
          _userPosition!.latitude,
          _userPosition!.longitude,
          10.0, // raio de 10km
        );

        setState(() {
          _postos = postos;
          _isLoading = false;
        });

        return true;
      }

      // Se não conseguiu via stream, tenta uma simulação
      developer.log('HomeScreen: Usando posição simulada para emulador');
      _userPosition = Position(
        latitude: -3.7480523,
        longitude: -38.5676128,
        timestamp: DateTime.now(),
        accuracy: 1.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      developer.log('==========================================');
      developer.log('HomeScreen: USANDO LOCALIZAÇÃO FICTÍCIA PARA EMULADOR!');
      developer.log(
        'LAT: ${_userPosition!.latitude}, LONG: ${_userPosition!.longitude}',
      );
      developer.log('==========================================');

      setState(() {
        _isLoading = true;
      });

      // Buscar postos com a posição simulada
      final postos = await ApiService.getPostosProximos(
        _userPosition!.latitude,
        _userPosition!.longitude,
        10.0, // raio de 10km
      );

      setState(() {
        _postos = postos;
        _isLoading = false;
      });

      return true;
    } catch (e) {
      developer.log('==========================================');
      developer.log('HomeScreen: FALHA ao obter localização para emulador: $e');
      developer.log('==========================================');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Autenticação mantida mas não exibida visualmente
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MediTrackLogo(size: 28),
            const SizedBox(width: 8),
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Medi',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: 'Track',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      // color: Color(0xFF4CD2DC), //cor turquesa como no login
                      color: Color(0xFF0080FF), //cor azul escuro
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // backgroundColor: const Color(0xFF0080FF),
        backgroundColor: const Color(0xFF40BFFF),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          // Botão para forçar atualização da localização
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarPostosProximos,
            tooltip: 'Atualizar localização',
          ),
        ],
      ),
      drawer: const Sidebar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              // Color(0xFF0080FF), // Azul mais escuro no topo
              Color(0xFF40BFFF), // Azul mais escuro no topo
              Color(0xFF40BFFF), // Azul mais claro embaixo
            ],
          ),
        ),
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
                          foregroundColor: const Color(0xFF40BFFF),
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

                        // Mostrar indicador de tipo de localização
                        if (_userPosition != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.my_location,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Utilizando sua localização em tempo real',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (_postos.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.info_outline,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Usando localização padrão',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.refresh,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  onPressed: _carregarPostosProximos,
                                  tooltip: 'Tentar obter localização atual',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
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
              color: Color(0xFF40BFFF),
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
                    backgroundColor: const Color(0xFF4CD2DC),
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
