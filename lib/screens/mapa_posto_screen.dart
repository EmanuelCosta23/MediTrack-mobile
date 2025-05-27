import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../widgets/sidebar.dart';
import 'home_screen.dart';
import 'detalhe_posto.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
  MapType _currentMapType = MapType.normal;
  bool _detalhesMinimizados = false;
  final LatLng _defaultLocation = const LatLng(-3.7480523, -38.5676128);
  BitmapDescriptor? _customIcon;

  @override
  void initState() {
    super.initState();
    developer.log(
      'MapaPostoScreen inicializada. mostrarTodosPostos: ${widget.mostrarTodosPostos}',
    );

    _loadCustomIcon();
    _configureGoogleMaps();

    if (widget.mostrarTodosPostos) {
      _obterLocalizacaoEmulador().then((localizacaoObtida) {
        if (!localizacaoObtida) {
          _obterLocalizacaoRealPrimeiro();
        }
      });
    } else {
      _inicializarMapaComPostoEspecifico();
    }
  }

  // Future<void> _loadCustomIcon() async {
  //   try {
  //     _customIcon = await BitmapDescriptor.fromAssetImage(
  //       const ImageConfiguration(size: Size(48, 48)),
  //       'assets/images/hospital_cross.png',
  //     );
  //     developer.log(
  //       'Ícone personalizado hospital_cross.png carregado com sucesso',
  //     );
  //   } catch (e) {
  //     developer.log('Erro ao carregar ícone personalizado: $e');
  //     _customIcon = BitmapDescriptor.defaultMarkerWithHue(
  //       BitmapDescriptor.hueRed,
  //     );
  //   }
  // }

  Future<void> _loadCustomIcon() async {
    try {
      // Define o tamanho baseado na plataforma
      int iconSize;
      if (kIsWeb) {
        iconSize = 48; // Tamanho maior para web
      } else {
        iconSize = 124; // Tamanho menor para mobile
      }

      // Carrega a imagem como bytes
      final ByteData data = await rootBundle.load(
        'assets/images/hospital_cross.png',
      );
      final Uint8List bytes = data.buffer.asUint8List();

      // Decodifica e redimensiona a imagem
      final ui.Codec codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: iconSize,
        targetHeight: iconSize,
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      // Converte para bytes PNG
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List resizedBytes = byteData!.buffer.asUint8List();

      // Cria o BitmapDescriptor
      _customIcon = BitmapDescriptor.fromBytes(resizedBytes);

      developer.log(
        'Ícone carregado - Plataforma: ${kIsWeb ? "Web" : "Mobile"}, '
        'Tamanho: ${iconSize}x${iconSize} pixels',
      );
    } catch (e) {
      developer.log('Erro ao carregar ícone personalizado: $e');
      _customIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueRed,
      );
    }
  }

  Future<void> _configureGoogleMaps() async {
    try {
      final GoogleMapsFlutterAndroid platform =
          GoogleMapsFlutterPlatform.instance as GoogleMapsFlutterAndroid;
      await platform.initializeWithRenderer(AndroidMapRenderer.latest);
      developer.log('Configurado renderizador LATEST com sucesso');
    } catch (e) {
      developer.log('Erro ao configurar renderizador do Google Maps: $e');
    }
  }

  Future<bool> _obterLocalizacaoEmulador() async {
    try {
      developer.log('==========================================');
      developer.log(
        'MapaPostoScreen: TENTANDO OBTER LOCALIZAÇÃO PARA EMULADOR',
      );
      developer.log('==========================================');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        developer.log('==========================================');
        developer.log('MapaPostoScreen: PERMISSÃO DE LOCALIZAÇÃO NEGADA');
        developer.log('==========================================');
        return false;
      }

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
        _inicializarMapaComTodosPostos();
        return true;
      }

      developer.log('MapaPostoScreen: Usando posição simulada para emulador');
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
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        developer.log('Serviço de localização desativado no início');
        _inicializarMapaComTodosPostos();
        return;
      }

      try {
        _userPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
          timeLimit: const Duration(seconds: 15),
        );
        developer.log(
          'SUCESSO INICIAL: Localização real obtida com alta precisão: ${_userPosition!.latitude}, ${_userPosition!.longitude}',
        );
        _inicializarMapaComTodosPostos();
      } catch (e) {
        developer.log(
          'FALHA INICIAL: Erro ao obter localização com alta precisão: $e',
        );
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
          await _carregarPostos();
          return;
        }
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      developer.log('Serviço de localização ativado: $serviceEnabled');

      if (!serviceEnabled) {
        developer.log('Serviço de localização desativado');
        setState(() {
          _erro =
              'O serviço de localização está desativado. Por favor, ative-o nas configurações do seu dispositivo.';
          _isLoading = false;
        });
        await _carregarPostos();
        return;
      }

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
      }

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
      await _carregarPostos();
    }
  }

  Future<void> _carregarPostos() async {
    try {
      if (_userPosition != null) {
        developer.log(
          'CARREGANDO POSTOS COM LOCALIZAÇÃO REAL: ${_userPosition!.latitude}, ${_userPosition!.longitude}',
        );
        final postos = await ApiService.getPostosProximos(
          _userPosition!.latitude,
          _userPosition!.longitude,
          20.0,
        );
        developer.log(
          'Postos encontrados com localização real: ${postos.length}',
        );
        setState(() {
          _postos = postos;
        });
      } else {
        try {
          developer.log(
            'CARREGANDO POSTOS COM LOCALIZAÇÃO PADRÃO: ${_defaultLocation.latitude}, ${_defaultLocation.longitude}',
          );
          final postos = await ApiService.getPostosProximos(
            _defaultLocation.latitude,
            _defaultLocation.longitude,
            20.0,
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

      await _adicionarMarcadoresPostos();
    } catch (e) {
      developer.log('Erro ao carregar postos: $e');
      setState(() {
        _erro = 'Não foi possível carregar postos próximos.';
      });
    }
  }

  Future<void> _adicionarMarcadoresPostos() async {
    developer.log('Adicionando marcadores para ${_postos.length} postos');
    Set<Marker> markers = {};

    if (_userPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(_userPosition!.latitude, _userPosition!.longitude),
          infoWindow: const InfoWindow(title: 'Sua localização atual'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          zIndex: 2,
        ),
      );
    }

    for (var posto in _postos) {
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
              icon:
                  _customIcon ??
                  BitmapDescriptor.defaultMarkerWithHue(
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

    if (_userPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_userPosition!.latitude, _userPosition!.longitude),
          13.0,
        ),
      );
    } else if (_postos.isNotEmpty && _mapController != null) {
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
          _adicionarMarcadorPostoEspecifico();
          return;
        }
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      developer.log('Serviço de localização ativado: $serviceEnabled');

      if (!serviceEnabled) {
        developer.log('Serviço de localização desativado');
        setState(() {
          _erro =
              'O serviço de localização está desativado. Por favor, ative-o nas configurações do seu dispositivo.';
          _isLoading = false;
        });
        _adicionarMarcadorPostoEspecifico();
        return;
      }

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
      }

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
      _adicionarMarcadorPostoEspecifico();
    }
  }

  void _adicionarMarcadorPostoEspecifico() {
    developer.log('Adicionando marcador para posto específico');
    Set<Marker> markers = {};

    if (widget.latitude != null && widget.longitude != null) {
      developer.log(
        'Adicionando marcador para posto: ${widget.latitude}, ${widget.longitude}',
      );
      markers.add(
        Marker(
          markerId: const MarkerId('posto'),
          position: LatLng(widget.latitude!, widget.longitude!),
          infoWindow: InfoWindow(
            title: widget.nome ?? 'Posto de saúde',
            snippet: widget.endereco ?? '',
          ),
          icon:
              _customIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

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

    controller.setMapStyle('[]');
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

  void _handleMapError() {
    developer.log('Erro ao carregar o mapa');
    setState(() {
      _mapError = true;
      _isLoading = false;
    });
  }

  void _showPostoDetails(Map<String, dynamic> posto) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                        color: Color(0xFF40BFFF),
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
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => DetalhePosto(
                                        nome: posto['nome'] ?? 'Posto de saúde',
                                        endereco:
                                            '${posto['rua'] ?? ''}, ${posto['numero'] ?? ''} - ${posto['bairro'] ?? ''}',
                                        id: posto['id'] ?? '',
                                      ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.info,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: const Text('Ver detalhes'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF40BFFF),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final url = Uri.parse(
                                'https://www.google.com/maps/dir/?api=1&destination=${posto['latitude']},${posto['longitude']}',
                              );
                              if (await canLaunchUrl(url)) {
                                await launchUrl(
                                  url,
                                  mode: LaunchMode.externalApplication,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Não foi possível abrir o Google Maps',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.directions,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: const Text('Ver Rotas'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF40BFFF),
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
          Icon(icon, color: const Color(0xFF40BFFF), size: 20),
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
        backgroundColor: const Color(0xFF40BFFF),
        foregroundColor: Colors.white,
        actions: [
          if (widget.mostrarTodosPostos)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _forcarAtualizacaoLocalizacao,
              tooltip: 'Atualizar localização',
            ),
          if (!_mapError)
            IconButton(
              icon: const Icon(Icons.layers),
              onPressed: _changeMapType,
              tooltip: 'Mudar tipo de mapa',
            ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
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
                child: CircularProgressIndicator(color: Color(0xFF40BFFF)),
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
                        backgroundColor: const Color(0xFF40BFFF),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              )
              : _buildMapView(),
    );
  }

  void _changeMapType() {
    setState(() {
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
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: true,
                zoomControlsEnabled: true,
                compassEnabled: true,
                liteModeEnabled: false,
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
        if (widget.mostrarTodosPostos ||
            (_userPosition != null && !widget.mostrarTodosPostos))
          Positioned(
            right: 10,
            bottom: 200,
            child: FloatingActionButton.small(
              onPressed: () {
                if (_userPosition != null && _mapController != null) {
                  _mapController!.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      LatLng(_userPosition!.latitude, _userPosition!.longitude),
                      14.0,
                    ),
                  );
                } else {
                  if (widget.mostrarTodosPostos) {
                    _inicializarMapaComTodosPostos();
                  } else {
                    _inicializarMapaComPostoEspecifico();
                  }
                }
              },
              backgroundColor: const Color(0xFF40BFFF),
              heroTag: 'my_location',
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        if (!widget.mostrarTodosPostos)
          Positioned(
            right: 10,
            bottom: 260,
            child: FloatingActionButton.small(
              onPressed: () {
                setState(() {
                  _detalhesMinimizados = !_detalhesMinimizados;
                });
              },
              backgroundColor: const Color(0xFF40BFFF),
              heroTag: 'toggle_details',
              child: Icon(
                _detalhesMinimizados ? Icons.info : Icons.info_outline,
                color: Colors.white,
              ),
            ),
          ),
        if (!widget.mostrarTodosPostos &&
            widget.nome != null &&
            !_detalhesMinimizados)
          Positioned(
            left: 10,
            right: 60,
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
                            onPressed: () async {
                              final url = Uri.parse(
                                'https://www.google.com/maps/dir/?api=1&destination=${widget.latitude},${widget.longitude}',
                              );
                              if (await canLaunchUrl(url)) {
                                await launchUrl(
                                  url,
                                  mode: LaunchMode.externalApplication,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Não foi possível abrir o Google Maps',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.directions,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: const Text('Ver Rotas'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF40BFFF),
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

        await _carregarPostos();

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
