import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../widgets/sidebar.dart';
import 'home_screen.dart'; // Importando a home
import 'dart:developer' as developer;

class MapaPostoScreen extends StatefulWidget {
  final String? nome;
  final String? endereco;
  final double? latitude;
  final double? longitude;
  final double? distancia;
  final bool mostrarTodosPostos;

  const MapaPostoScreen({
    super.key,
    this.nome,
    this.endereco,
    this.latitude,
    this.longitude,
    this.distancia,
    this.mostrarTodosPostos = false,
  });

  @override
  State<MapaPostoScreen> createState() => _MapaPostoScreenState();
}

class _MapaPostoScreenState extends State<MapaPostoScreen> {
  GoogleMapController? _mapController;
  Position? _userPosition;
  bool _isLoading = true;
  String _erro = '';
  Set<Marker> _markers = {};
  List<dynamic> _postos = [];
  bool _mapInitialized = false;
  bool _mapError = false;
  MapType _currentMapType = MapType.normal; // Tipo de mapa atual
  bool _detalhesMinimizados =
      false; // Controlar se os detalhes estão minimizados
  final LatLng _defaultLocation = const LatLng(
    -3.7480523,
    -38.5676128,
  ); // Fortaleza, CE

  @override
  void initState() {
    super.initState();
    developer.log(
      'MapaPostoScreen inicializada. mostrarTodosPostos: ${widget.mostrarTodosPostos}',
    );

    // Configurar o Google Maps
    _configureGoogleMaps();

    // Forçar a obtenção da localização real primeiro
    if (widget.mostrarTodosPostos) {
      // Primeiro tentar obter a localização específica para emulador
      _obterLocalizacaoEmulador().then((localizacaoObtida) {
        if (!localizacaoObtida) {
          // Se falhar, usar o método padrão
          _obterLocalizacaoRealPrimeiro();
        }
      });
    } else {
      _inicializarMapaComPostoEspecifico();
    }
  }

  Future<void> _configureGoogleMaps() async {
    try {
      // Configurar o renderizador para o Android
      final GoogleMapsFlutterAndroid platform =
          GoogleMapsFlutterPlatform.instance as GoogleMapsFlutterAndroid;

      // Desativar o modo lite para permitir gestos e ter funcionalidade completa
      await platform.initializeWithRenderer(AndroidMapRenderer.latest);
      developer.log('Configurado renderizador LATEST com sucesso');
    } catch (e) {
      developer.log('Erro ao configurar renderizador do Google Maps: $e');
      // Continue mesmo com erro de configuração
    }
  }

  Future<bool> _obterLocalizacaoEmulador() async {
    try {
      developer.log('==========================================');
      developer.log(
        'MapaPostoScreen: TENTANDO OBTER LOCALIZAÇÃO PARA EMULADOR',
      );
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
        developer.log('MapaPostoScreen: PERMISSÃO DE LOCALIZAÇÃO NEGADA');
        developer.log('==========================================');
        return false;
      }

      // No emulador, às vezes precisamos forçar uma localização manualmente
      // Verificar se já existe uma posição simulada no emulador
      developer.log('MapaPostoScreen: Tentando obter via stream (emulador)...');
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
          'MapaPostoScreen: SUCESSO NO EMULADOR: Posição obtida via stream!',
        );
        developer.log(
          'LAT: ${_userPosition!.latitude}, LONG: ${_userPosition!.longitude}',
        );
        developer.log('==========================================');

        // Inicializar o mapa com a posição obtida
        _inicializarMapaComTodosPostos();
        return true;
      }

      // Se não conseguiu via stream, tenta o mock para emulador
      developer.log('MapaPostoScreen: Usando posição simulada para emulador');
      // Essa é uma localização fictícia que você pode configurar no emulador
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
      developer.log(
        'MapaPostoScreen: USANDO LOCALIZAÇÃO FICTÍCIA PARA EMULADOR!',
      );
      developer.log(
        'LAT: ${_userPosition!.latitude}, LONG: ${_userPosition!.longitude}',
      );
      developer.log('==========================================');

      // Inicializar o mapa com a posição mock
      _inicializarMapaComTodosPostos();
      return true;
    } catch (e) {
      developer.log('==========================================');
      developer.log(
        'MapaPostoScreen: FALHA ao obter localização para emulador: $e',
      );
      developer.log('==========================================');
      return false;
    }
  }

  Future<void> _obterLocalizacaoRealPrimeiro() async {
    try {
      developer.log('Obtendo localização real no início do aplicativo...');
      // Verificar permissões
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // Verificar serviço
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        developer.log('Serviço de localização desativado no início');
        _inicializarMapaComTodosPostos();
        return;
      }

      // Tentar obter localização com alta precisão
      try {
        _userPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
          timeLimit: const Duration(seconds: 15),
        );
        developer.log(
          'SUCESSO INICIAL: Localização real obtida com alta precisão: ${_userPosition!.latitude}, ${_userPosition!.longitude}',
        );

        // Se obteve a localização com sucesso, inicializar o mapa
        _inicializarMapaComTodosPostos();
      } catch (e) {
        developer.log(
          'FALHA INICIAL: Erro ao obter localização com alta precisão: $e',
        );
        // Tentar com precisão menor
        _inicializarMapaComTodosPostos();
      }
    } catch (e) {
      developer.log('Erro ao obter localização inicial: $e');
      _inicializarMapaComTodosPostos();
    }
  }

  Future<void> _inicializarMapaComTodosPostos() async {
    developer.log('Inicializando mapa com todos os postos');
    setState(() {
      _isLoading = true;
      _erro = '';
    });

    try {
      // Verificar e solicitar permissão de localização
      LocationPermission permission = await Geolocator.checkPermission();
      developer.log('Permissão atual: $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        developer.log('Permissão após solicitação: $permission');

        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          developer.log('Permissão negada pelo usuário');
          setState(() {
            _erro =
                'Não foi possível acessar sua localização. Verifique as permissões do aplicativo.';
            _isLoading = false;
          });
          // Mesmo sem permissão, podemos carregar os postos
          await _carregarPostos();
          return;
        }
      }

      // Verificar se o serviço de localização está ativado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      developer.log('Serviço de localização ativado: $serviceEnabled');

      if (!serviceEnabled) {
        developer.log('Serviço de localização desativado');
        setState(() {
          _erro =
              'O serviço de localização está desativado. Por favor, ative-o nas configurações do seu dispositivo.';
          _isLoading = false;
        });
        // Mesmo sem serviço, podemos carregar os postos
        await _carregarPostos();
        return;
      }

      // Obter localização atual - com várias tentativas
      try {
        developer.log('Tentando obter posição atual com alta precisão...');
        try {
          _userPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 10),
          );
          developer.log(
            'SUCESSO: Posição obtida com alta precisão: ${_userPosition?.latitude}, ${_userPosition?.longitude}',
          );
        } catch (e) {
          developer.log(
            'FALHA: Erro ao obter posição com alta precisão: $e. Tentando com precisão menor...',
          );
          try {
            _userPosition = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium,
              timeLimit: const Duration(seconds: 8),
            );
            developer.log(
              'SUCESSO: Posição obtida com precisão média: ${_userPosition?.latitude}, ${_userPosition?.longitude}',
            );
          } catch (e) {
            developer.log(
              'FALHA: Erro ao obter posição com precisão média: $e. Tentando com última localização conhecida...',
            );
            try {
              _userPosition = await Geolocator.getLastKnownPosition();
              if (_userPosition != null) {
                developer.log(
                  'SUCESSO: Última posição conhecida obtida: ${_userPosition?.latitude}, ${_userPosition?.longitude}',
                );
              } else {
                developer.log(
                  'FALHA: Não foi possível obter a última posição conhecida.',
                );
              }
            } catch (e) {
              developer.log(
                'FALHA: Erro ao obter última posição conhecida: $e',
              );
            }
          }
        }

        if (_userPosition != null) {
          developer.log(
            'USANDO LOCALIZAÇÃO REAL: ${_userPosition!.latitude}, ${_userPosition!.longitude}',
          );
        } else {
          developer.log(
            'USANDO LOCALIZAÇÃO PADRÃO: ${_defaultLocation.latitude}, ${_defaultLocation.longitude}',
          );
        }
      } catch (e) {
        developer.log('Erro geral ao obter posição: $e');
        // Continuar mesmo sem a posição atual
      }

      // Carregar postos próximos
      await _carregarPostos();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Erro ao inicializar mapa: $e');
      setState(() {
        _erro =
            'Ocorreu um erro ao carregar o mapa. Verifique sua conexão e tente novamente.';
        _isLoading = false;
      });

      // Mesmo com erro, tentar carregar postos
      await _carregarPostos();
    }
  }

  Future<void> _carregarPostos() async {
    try {
      if (_userPosition != null) {
        // Se temos a posição do usuário, buscar postos próximos
        developer.log(
          'CARREGANDO POSTOS COM LOCALIZAÇÃO REAL: ${_userPosition!.latitude}, ${_userPosition!.longitude}',
        );
        final postos = await ApiService.getPostosProximos(
          _userPosition!.latitude,
          _userPosition!.longitude,
          20.0, // raio de 20km
        );
        developer.log(
          'Postos encontrados com localização real: ${postos.length}',
        );
        setState(() {
          _postos = postos;
        });
      } else {
        // Se não temos a posição, tentar buscar todos os postos
        try {
          // Usar posição padrão para buscar postos
          developer.log(
            'CARREGANDO POSTOS COM LOCALIZAÇÃO PADRÃO: ${_defaultLocation.latitude}, ${_defaultLocation.longitude}',
          );
          final postos = await ApiService.getPostosProximos(
            _defaultLocation.latitude,
            _defaultLocation.longitude,
            20.0, // raio de 20km
          );
          developer.log(
            'Postos encontrados com localização padrão: ${postos.length}',
          );
          setState(() {
            _postos = postos;
          });
        } catch (e) {
          developer.log('Erro ao buscar postos em posição padrão: $e');
          setState(() {
            _erro = 'Não foi possível carregar postos próximos.';
          });
        }
      }

      // Adicionar marcadores para os postos
      _adicionarMarcadoresPostos();
    } catch (e) {
      developer.log('Erro ao carregar postos: $e');
      setState(() {
        _erro = 'Não foi possível carregar postos próximos.';
      });
    }
  }

  void _adicionarMarcadoresPostos() {
    developer.log('Adicionando marcadores para ${_postos.length} postos');
    // Conjunto de marcadores
    Set<Marker> markers = {};

    // Adicionar marcador para posição atual
    if (_userPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(_userPosition!.latitude, _userPosition!.longitude),
          infoWindow: const InfoWindow(title: 'Sua localização atual'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          zIndex: 2, // Para ficar acima dos outros marcadores
        ),
      );
    }

    // Adicionar marcadores para os postos
    for (var posto in _postos) {
      // Verificar se temos latitude e longitude do posto
      if (posto['latitude'] != null && posto['longitude'] != null) {
        final double? lat = double.tryParse(posto['latitude'].toString());
        final double? lng = double.tryParse(posto['longitude'].toString());

        if (lat != null && lng != null) {
          markers.add(
            Marker(
              markerId: MarkerId(
                posto['id'] ?? 'posto_${_postos.indexOf(posto)}',
              ),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: posto['nome'] ?? 'Posto de saúde',
                snippet:
                    '${posto['rua'] ?? ''}, ${posto['numero'] ?? ''} - ${posto['bairro'] ?? ''}',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
              onTap: () {
                _showPostoDetails(posto);
              },
            ),
          );
        }
      }
    }

    developer.log('Total de marcadores adicionados: ${markers.length}');
    setState(() {
      _markers = markers;
    });

    // Se temos a posição do usuário, centralizar nela
    if (_userPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_userPosition!.latitude, _userPosition!.longitude),
          13.0,
        ),
      );
    }
    // Se não temos a posição mas temos postos, centralizar no primeiro posto
    else if (_postos.isNotEmpty && _mapController != null) {
      final posto = _postos.first;
      final double? lat = double.tryParse(posto['latitude'].toString());
      final double? lng = double.tryParse(posto['longitude'].toString());

      if (lat != null && lng != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(lat, lng), 13.0),
        );
      }
    }
  }

  Future<void> _inicializarMapaComPostoEspecifico() async {
    developer.log('Inicializando mapa com posto específico: ${widget.nome}');
    developer.log(
      'Coordenadas do posto: ${widget.latitude}, ${widget.longitude}',
    );

    setState(() {
      _isLoading = true;
      _erro = '';
    });

    try {
      // Verificar e solicitar permissão de localização
      LocationPermission permission = await Geolocator.checkPermission();
      developer.log('Permissão atual: $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        developer.log('Permissão após solicitação: $permission');

        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          developer.log('Permissão negada pelo usuário');
          setState(() {
            _erro =
                'Não foi possível acessar sua localização. Verifique as permissões do aplicativo.';
            _isLoading = false;
          });

          // Ainda podemos mostrar o posto sem a localização do usuário
          _adicionarMarcadorPostoEspecifico();
          return;
        }
      }

      // Verificar se o serviço de localização está ativado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      developer.log('Serviço de localização ativado: $serviceEnabled');

      if (!serviceEnabled) {
        developer.log('Serviço de localização desativado');
        setState(() {
          _erro =
              'O serviço de localização está desativado. Por favor, ative-o nas configurações do seu dispositivo.';
          _isLoading = false;
        });

        // Ainda podemos mostrar o posto sem a localização do usuário
        _adicionarMarcadorPostoEspecifico();
        return;
      }

      // Obter localização atual com várias tentativas
      try {
        developer.log(
          'Tentando obter posição atual com alta precisão (modo específico)...',
        );
        try {
          _userPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 10),
          );
          developer.log(
            'SUCESSO (modo específico): Posição obtida com alta precisão: ${_userPosition?.latitude}, ${_userPosition?.longitude}',
          );
        } catch (e) {
          developer.log(
            'FALHA (modo específico): Erro ao obter posição com alta precisão: $e. Tentando com precisão menor...',
          );
          try {
            _userPosition = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium,
              timeLimit: const Duration(seconds: 8),
            );
            developer.log(
              'SUCESSO (modo específico): Posição obtida com precisão média: ${_userPosition?.latitude}, ${_userPosition?.longitude}',
            );
          } catch (e) {
            developer.log(
              'FALHA (modo específico): Erro ao obter posição com precisão média: $e. Tentando com última localização conhecida...',
            );
            try {
              _userPosition = await Geolocator.getLastKnownPosition();
              if (_userPosition != null) {
                developer.log(
                  'SUCESSO (modo específico): Última posição conhecida obtida: ${_userPosition?.latitude}, ${_userPosition?.longitude}',
                );
              } else {
                developer.log(
                  'FALHA (modo específico): Não foi possível obter a última posição conhecida.',
                );
              }
            } catch (e) {
              developer.log(
                'FALHA (modo específico): Erro ao obter última posição conhecida: $e',
              );
            }
          }
        }

        if (_userPosition != null) {
          developer.log(
            'USANDO LOCALIZAÇÃO REAL (modo específico): ${_userPosition!.latitude}, ${_userPosition!.longitude}',
          );
        } else {
          developer.log(
            'LOCALIZAÇÃO DO USUÁRIO NÃO DISPONÍVEL (modo específico). Usando apenas a localização do posto.',
          );
        }
      } catch (e) {
        developer.log('Erro geral ao obter posição (modo específico): $e');
        // Continuar mesmo sem a posição atual
      }

      // Adicionar marcadores
      _adicionarMarcadorPostoEspecifico();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Erro ao inicializar mapa com posto específico: $e');
      setState(() {
        _erro =
            'Ocorreu um erro ao carregar o mapa. Verifique sua conexão e tente novamente.';
        _isLoading = false;
      });

      // Tentar mostrar o posto mesmo com erro
      _adicionarMarcadorPostoEspecifico();
    }
  }

  void _adicionarMarcadorPostoEspecifico() {
    developer.log('Adicionando marcador para posto específico');
    // Conjunto de marcadores
    Set<Marker> markers = {};

    // Verificar se temos latitude e longitude
    if (widget.latitude != null && widget.longitude != null) {
      developer.log(
        'Adicionando marcador para posto: ${widget.latitude}, ${widget.longitude}',
      );
      // Marcador do posto
      markers.add(
        Marker(
          markerId: const MarkerId('posto'),
          position: LatLng(widget.latitude!, widget.longitude!),
          infoWindow: InfoWindow(
            title: widget.nome ?? 'Posto de saúde',
            snippet: widget.endereco ?? '',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    // Marcador do usuário (se disponível)
    if (_userPosition != null) {
      developer.log(
        'Adicionando marcador para usuário: ${_userPosition!.latitude}, ${_userPosition!.longitude}',
      );
      markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: LatLng(_userPosition!.latitude, _userPosition!.longitude),
          infoWindow: const InfoWindow(title: 'Sua localização'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    developer.log('Total de marcadores adicionados: ${markers.length}');
    setState(() {
      _markers = markers;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    developer.log('Mapa criado com sucesso');
    setState(() {
      _mapController = controller;
      _mapInitialized = true;
    });

    // Forçar uma atualização do mapa
    controller.setMapStyle('[]'); // Estilo vazio para garantir renderização
    controller.moveCamera(
      CameraUpdate.newLatLngZoom(
        widget.mostrarTodosPostos
            ? (_userPosition != null
                ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
                : _defaultLocation)
            : (widget.latitude != null && widget.longitude != null
                ? LatLng(widget.latitude!, widget.longitude!)
                : _defaultLocation),
        13.0,
      ),
    );
  }

  // Método para lidar com falha no carregamento do mapa
  void _handleMapError() {
    developer.log('Erro ao carregar o mapa');
    setState(() {
      _mapError = true;
      _isLoading = false;
    });
  }

  // Exibe detalhes do posto em um modal
  void _showPostoDetails(Map<String, dynamic> posto) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.3,
            maxChildSize: 0.7,
            expand: false,
            builder:
                (_, scrollController) => SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.only(bottom: 20),
                          ),
                        ),
                        Text(
                          posto['nome'] ?? 'Posto de saúde',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0080FF),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.location_on,
                          '${posto['rua'] ?? ''}, ${posto['numero'] ?? ''} - ${posto['bairro'] ?? ''}',
                        ),
                        if (posto['telefone'] != null &&
                            posto['telefone'].toString().isNotEmpty)
                          _buildInfoRow(Icons.phone, posto['telefone']),
                        if (posto['distancia'] != null)
                          _buildInfoRow(
                            Icons.directions_walk,
                            '${posto['distancia'].toStringAsFixed(1)} km de distância',
                          ),
                        if (posto['linhasOnibus'] != null ||
                            posto['linhasOnibusPosto'] != null)
                          _buildInfoRow(
                            Icons.directions_bus,
                            'Linhas de ônibus: ${posto['linhasOnibus'] ?? posto['linhasOnibusPosto'] ?? ''}',
                          ),
                        const SizedBox(height: 20),
                        // Botões horizontais ocupando toda a largura
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Centralizar no posto
                                  final double? lat = double.tryParse(
                                    posto['latitude']?.toString() ?? '',
                                  );
                                  final double? lng = double.tryParse(
                                    posto['longitude']?.toString() ?? '',
                                  );

                                  if (lat != null &&
                                      lng != null &&
                                      _mapController != null) {
                                    _mapController!.animateCamera(
                                      CameraUpdate.newLatLngZoom(
                                        LatLng(lat, lng),
                                        16.0,
                                      ),
                                    );
                                    Navigator.pop(context);
                                  }
                                },
                                icon: const Icon(
                                  Icons.place,
                                  color: Colors.white,
                                ),
                                label: const Text('Ver no mapa'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0080FF),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            if (_userPosition != null) const SizedBox(width: 8),
                            if (_userPosition != null)
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // Centralizar na localização do usuário
                                    _mapController?.animateCamera(
                                      CameraUpdate.newLatLngZoom(
                                        LatLng(
                                          _userPosition!.latitude,
                                          _userPosition!.longitude,
                                        ),
                                        16.0,
                                      ),
                                    );
                                    Navigator.pop(context);
                                  },
                                  icon: const Icon(
                                    Icons.my_location,
                                    color: Colors.white,
                                  ),
                                  label: const Text('Minha localização'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0080FF),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF0080FF), size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.mostrarTodosPostos
              ? 'Mapa de Postos de Saúde'
              : 'Localização do Posto',
        ),
        backgroundColor: const Color(0xFF0080FF),
        foregroundColor: Colors.white,
        actions: [
          // Botão para forçar a atualização da localização
          if (widget.mostrarTodosPostos)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _forcarAtualizacaoLocalizacao,
              tooltip: 'Atualizar localização',
            ),
          // Botão para alternar entre os tipos de mapa
          if (!_mapError)
            IconButton(
              icon: const Icon(Icons.layers),
              onPressed: _changeMapType,
              tooltip: 'Mudar tipo de mapa',
            ),
          // Botão Home
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false, // Remove todas as rotas anteriores
              );
            },
            tooltip: 'Ir para Home',
          ),
        ],
      ),
      drawer: widget.mostrarTodosPostos ? const Sidebar() : null,
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF0080FF)),
              )
              : _erro.isNotEmpty || _mapError
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _erro.isNotEmpty
                            ? _erro
                            : 'Não foi possível carregar o mapa.',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    ElevatedButton(
                      onPressed:
                          widget.mostrarTodosPostos
                              ? _carregarPostos
                              : _adicionarMarcadorPostoEspecifico,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0080FF),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              )
              : _buildMapView(),
      // Botão flutuante para centralizar na localização do usuário (apenas para mostrar todos os postos)
      floatingActionButton:
          widget.mostrarTodosPostos
              ? Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FloatingActionButton.small(
                    onPressed: () {
                      if (_mapController != null) {
                        _mapController!.animateCamera(CameraUpdate.zoomIn());
                      }
                    },
                    backgroundColor: const Color(0xFF0080FF),
                    heroTag: 'zoom_in',
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton.small(
                    onPressed: () {
                      if (_mapController != null) {
                        _mapController!.animateCamera(CameraUpdate.zoomOut());
                      }
                    },
                    backgroundColor: const Color(0xFF0080FF),
                    heroTag: 'zoom_out',
                    child: const Icon(Icons.remove, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton(
                    onPressed: () {
                      if (_userPosition != null && _mapController != null) {
                        _mapController!.animateCamera(
                          CameraUpdate.newLatLngZoom(
                            LatLng(
                              _userPosition!.latitude,
                              _userPosition!.longitude,
                            ),
                            14.0,
                          ),
                        );
                      } else {
                        // Se não temos a localização, tentar obtê-la
                        _inicializarMapaComTodosPostos();
                      }
                    },
                    backgroundColor: const Color(0xFF0080FF),
                    heroTag: 'my_location',
                    child: const Icon(Icons.my_location, color: Colors.white),
                  ),
                ],
              )
              : null,
    );
  }

  // Mudar o tipo do mapa
  void _changeMapType() {
    setState(() {
      // Alternar entre os tipos de mapa (Normal, Satélite, Terreno, Híbrido)
      if (_currentMapType == MapType.normal) {
        _currentMapType = MapType.satellite;
      } else if (_currentMapType == MapType.satellite) {
        _currentMapType = MapType.terrain;
      } else if (_currentMapType == MapType.terrain) {
        _currentMapType = MapType.hybrid;
      } else {
        _currentMapType = MapType.normal;
      }
    });
  }

  // Construir a visualização em mapa
  Widget _buildMapView() {
    return Stack(
      children: [
        Builder(
          builder: (context) {
            try {
              developer.log('Tentando renderizar o mapa');
              return GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target:
                      widget.mostrarTodosPostos
                          ? (_userPosition != null
                              ? LatLng(
                                _userPosition!.latitude,
                                _userPosition!.longitude,
                              )
                              : _defaultLocation)
                          : (widget.latitude != null && widget.longitude != null
                              ? LatLng(widget.latitude!, widget.longitude!)
                              : _defaultLocation),
                  zoom: 13.0,
                ),
                markers: _markers,
                myLocationEnabled: true, // Habilitar a localização real
                myLocationButtonEnabled: false,
                mapToolbarEnabled: true,
                zoomControlsEnabled: true,
                compassEnabled: true,
                liteModeEnabled:
                    false, // Desativar o modo lite para permitir gestos
                mapType: _currentMapType,
                zoomGesturesEnabled: true,
                rotateGesturesEnabled: true,
                scrollGesturesEnabled: true,
                tiltGesturesEnabled: true,
              );
            } catch (e) {
              developer.log('Erro ao renderizar o mapa: $e');
              Future.microtask(() => _handleMapError());
              return Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Text(
                    'Não foi possível carregar o mapa.',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              );
            }
          },
        ),

        // Botões de controle na parte inferior direita
        if (!widget.mostrarTodosPostos)
          Positioned(
            right: 16,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botão para minimizar/maximizar detalhes do posto
                FloatingActionButton.small(
                  onPressed: () {
                    setState(() {
                      _detalhesMinimizados = !_detalhesMinimizados;
                    });
                  },
                  backgroundColor: const Color(0xFF0080FF),
                  heroTag: 'toggle_details',
                  child: Icon(
                    _detalhesMinimizados ? Icons.info : Icons.info_outline,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                // Botão de zoom +
                FloatingActionButton.small(
                  onPressed: () {
                    if (_mapController != null) {
                      _mapController!.animateCamera(CameraUpdate.zoomIn());
                    }
                  },
                  backgroundColor: const Color(0xFF0080FF),
                  heroTag: 'zoom_in_specific',
                  child: const Icon(Icons.add, color: Colors.white),
                ),
                const SizedBox(height: 8),
                // Botão de zoom -
                FloatingActionButton.small(
                  onPressed: () {
                    if (_mapController != null) {
                      _mapController!.animateCamera(CameraUpdate.zoomOut());
                    }
                  },
                  backgroundColor: const Color(0xFF0080FF),
                  heroTag: 'zoom_out_specific',
                  child: const Icon(Icons.remove, color: Colors.white),
                ),
              ],
            ),
          ),

        // Card com informações do posto (apenas para posto específico)
        if (!widget.mostrarTodosPostos &&
            widget.nome != null &&
            !_detalhesMinimizados)
          Positioned(
            left: 10,
            right: 70, // Deixar espaço para os botões de zoom
            bottom: 10,
            child: Container(
              margin: const EdgeInsets.all(8.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.nome!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.endereco ?? '',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.distancia != null) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Color(0xFF0080FF),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.distancia!.toStringAsFixed(1)} km',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        alignment: WrapAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              // Zoom para o posto
                              _mapController?.animateCamera(
                                CameraUpdate.newLatLngZoom(
                                  LatLng(widget.latitude!, widget.longitude!),
                                  18.0,
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.local_hospital,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: const Text('Posto'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0080FF),
                              foregroundColor: Colors.white,
                            ),
                          ),
                          if (_userPosition != null)
                            ElevatedButton.icon(
                              onPressed: () {
                                // Zoom para a localização do usuário
                                _mapController?.animateCamera(
                                  CameraUpdate.newLatLngZoom(
                                    LatLng(
                                      _userPosition!.latitude,
                                      _userPosition!.longitude,
                                    ),
                                    18.0,
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.my_location,
                                size: 18,
                                color: Colors.white,
                              ),
                              label: const Text('Minha local.'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0080FF),
                                foregroundColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Força a atualização da localização real
  Future<void> _forcarAtualizacaoLocalizacao() async {
    setState(() {
      _isLoading = true;
    });

    developer.log('==========================================');
    developer.log(
      'MapaPostoScreen: FORÇANDO ATUALIZAÇÃO DA LOCALIZAÇÃO REAL...',
    );
    developer.log('==========================================');

    try {
      // Primeiro, verificar permissões
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          developer.log('==========================================');
          developer.log(
            'MapaPostoScreen: PERMISSÃO DE LOCALIZAÇÃO NEGADA AO FORÇAR ATUALIZAÇÃO!',
          );
          developer.log('==========================================');
          setState(() {
            _erro =
                'Permissão de localização negada. Ative nas configurações do dispositivo.';
            _isLoading = false;
          });
          return;
        }
      }

      // Verificar se o serviço está ativado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        developer.log('==========================================');
        developer.log(
          'MapaPostoScreen: SERVIÇO DE LOCALIZAÇÃO DESATIVADO AO FORÇAR ATUALIZAÇÃO!',
        );
        developer.log('==========================================');
        setState(() {
          _erro =
              'Serviço de localização desativado. Ative nas configurações do dispositivo.';
          _isLoading = false;
        });
        return;
      }

      // Tentar obter a localização atual com alta precisão
      developer.log(
        'MapaPostoScreen: Obtendo localização com alta precisão (forçado)...',
      );
      Position? novaPosition;

      try {
        novaPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
          timeLimit: const Duration(seconds: 15),
        );
        developer.log('==========================================');
        developer.log(
          'MapaPostoScreen: SUCESSO (FORÇADO): Localização obtida com alta precisão!',
        );
        developer.log(
          'LAT: ${novaPosition.latitude}, LONG: ${novaPosition.longitude}',
        );
        developer.log('==========================================');
      } catch (e) {
        developer.log('==========================================');
        developer.log(
          'MapaPostoScreen: FALHA (FORÇADO): Erro ao obter localização com alta precisão: $e',
        );
        developer.log('==========================================');
        try {
          novaPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 10),
          );
          developer.log('==========================================');
          developer.log(
            'MapaPostoScreen: SUCESSO (FORÇADO): Localização obtida com precisão alta!',
          );
          developer.log(
            'LAT: ${novaPosition.latitude}, LONG: ${novaPosition.longitude}',
          );
          developer.log('==========================================');
        } catch (e) {
          developer.log('==========================================');
          developer.log(
            'MapaPostoScreen: FALHA (FORÇADO): Erro ao obter localização: $e',
          );
          developer.log('==========================================');
          setState(() {
            _erro = 'Não foi possível obter sua localização atual.';
            _isLoading = false;
          });
          return;
        }
      }

      // Se obtiver uma nova posição, atualizar
      if (novaPosition != null) {
        setState(() {
          _userPosition = novaPosition;
          _erro = '';
        });

        developer.log('==========================================');
        developer.log('MapaPostoScreen: LOCALIZAÇÃO ATUALIZADA (FORÇADO)!');
        developer.log(
          'LAT: ${_userPosition!.latitude}, LONG: ${_userPosition!.longitude}',
        );
        developer.log('==========================================');

        // Recarregar postos com a nova localização
        await _carregarPostos();

        // Atualizar a visualização do mapa
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(_userPosition!.latitude, _userPosition!.longitude),
              14.0,
            ),
          );
        }
      }
    } catch (e) {
      developer.log('==========================================');
      developer.log(
        'MapaPostoScreen: ERRO AO FORÇAR ATUALIZAÇÃO DA LOCALIZAÇÃO: $e',
      );
      developer.log('==========================================');
      setState(() {
        _erro = 'Erro ao atualizar localização: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
