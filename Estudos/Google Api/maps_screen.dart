import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  final Set<Marker> _markers = {};
  BitmapDescriptor? _healthPostIcon;
  StreamSubscription<Position>? _positionStreamSubscription;

  // Configurações para melhorar a precisão
  final LocationSettings _locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 5, // Atualiza a cada 5 metros de movimento
    timeLimit: Duration(seconds: 10), // Tempo limite para obter localização
  );

  // Lista de postos de saúde
  final List<Map<String, dynamic>> _postosList = [
    {
      'id': 'c0372982-1700-4b46-b5e6-34da959d733a',
      'nome': 'Posto de Saude Guiomar Arruda',
      'bairro': 'Pirambu',
      'rua': 'Rua Gal Costa Matos',
      'numero': '6',
      'linhas_onibus': '16; 51; 55; 92; 101; 120; 130; 132; 711; 725',
      'telefone': '(85) 3452-6377',
      'latitude': -3.71331065,
      'longitude': -38.54555071338716,
    },
    {
      'id': '78dd99cb-6983-432c-bcc1-c189ad668672',
      'nome': 'Posto de Saude 4 Varas',
      'bairro': 'Barra do Ceara',
      'rua': 'Rua Profeta Isaias',
      'numero': '456',
      'linhas_onibus': '110; 140',
      'telefone': '(85) 3101-2594',
      'latitude': -3.70154165,
      'longitude': -38.57337644748881,
    },
    {
      'id': '7e85ea26-e3fb-483d-94fc-8c9cc689d924',
      'nome': 'Posto de Saude Abel Pinto',
      'bairro': 'Democrito Rocha',
      'rua': 'Travessa Goias',
      'numero': 'S/N',
      'linhas_onibus': '308',
      'telefone': '(85) 3452-5191',
      'latitude': -3.7599222,
      'longitude': -38.5663099,
    },
    {
      'id': 'a39863a0-ebd9-4034-bee6-c7fa65d8d029',
      'nome': 'Posto de Saude Abner Cavalcante Brasil',
      'bairro': 'Bom Jardim',
      'rua': 'Rua Joana Batista',
      'numero': '471',
      'linhas_onibus': '342',
      'telefone': '(85) 3452-2468',
      'latitude': -3.80469595,
      'longitude': -38.60869320481698,
    },
    {
      'id': '84320007-a086-4ef5-bd13-fcaf9bbdbf36',
      'nome': 'Posto de Saude Acriusio Eufrasino de Pinho',
      'bairro': 'Pedras',
      'rua': 'Rua Coletora Central',
      'numero': 'S/N',
      'linhas_onibus': '620; 681',
      'telefone': '',
      'latitude': -3.8777729,
      'longitude': -38.5144588,
    },
  ];

  @override
  void initState() {
    super.initState();
    _createCustomMarkerIcon();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _createCustomMarkerIcon() async {
    // Versão otimizada para emuladores - usa um ícone mais simples
    if (kIsWeb) {
      // Para Web, manter o código existente usando Canvas
      try {
        final pictureRecorder = ui.PictureRecorder();
        final canvas = ui.Canvas(pictureRecorder);
        final size = 48.0;
        final halfSize = size / 2;

        final paint = ui.Paint()
          ..color = Colors.white
          ..style = ui.PaintingStyle.fill;

        final strokePaint = ui.Paint()
          ..color = const Color(0xFF0080FF)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 2.0;

        final redPaint = ui.Paint()
          ..color = Colors.red
          ..style = ui.PaintingStyle.fill;

        canvas.drawCircle(Offset(halfSize, halfSize), halfSize - 4, paint);
        canvas.drawCircle(
            Offset(halfSize, halfSize), halfSize - 4, strokePaint);
        canvas.drawRect(
            Rect.fromLTWH(halfSize - 4, halfSize - 12, 8, 24), redPaint);
        canvas.drawRect(
            Rect.fromLTWH(halfSize - 12, halfSize - 4, 24, 8), redPaint);

        final picture = pictureRecorder.endRecording();
        final image = await picture.toImage(size.toInt(), size.toInt());
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

        if (byteData != null) {
          final uint8List = byteData.buffer.asUint8List();
          setState(() {
            _healthPostIcon = BitmapDescriptor.bytes(uint8List);
          });
        }
      } catch (e) {
        print("Erro ao criar ícone personalizado: $e");
        // Fallback para ícone padrão
        _healthPostIcon =
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      }
    } else {
      // Para dispositivos móveis/emuladores, usar abordagem mais simples
      setState(() {
        _healthPostIcon =
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      });
    }
  }

  Future<void> _checkLocationPermission() async {
    try {
      // Verificar se o serviço de localização está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
        });
        _showLocationServiceDisabledDialog();
        return;
      }

      // Verificar permissão de localização
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
          });
          _showPermissionDeniedDialog();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
        });
        _showPermissionDeniedDialog();
        return;
      }

      // Se chegou aqui, tem permissão
      _getCurrentLocation();
    } catch (e) {
      print("Erro ao verificar permissão: $e");
      setState(() {
        _isLoading = false;
      });
      // Mesmo com erro, mostrar os postos
      _addMarkers();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Para plataforma web ou emulador, simplificar para evitar travamentos
      if (kIsWeb || true) {
        // Sempre usar a versão simplificada para melhorar performance
        // Obter apenas a posição atual, sem última posição conhecida
        try {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy
                .high, // Reduzir precisão para melhorar performance
            timeLimit: const Duration(seconds: 5), // Tempo limite menor
          );

          setState(() {
            _currentPosition = position;
            _isLoading = false;
          });

          _addMarkers();

          if (_mapController != null && _currentPosition != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                14.0,
              ),
            );
          }
        } catch (e) {
          print("Erro ao obter localização atual: $e");
          setState(() {
            _isLoading = false;
          });
          // Mostrar os postos mesmo sem localização
          _addMarkers();
        }

        // Usar atualização de localização mais econômica
        _positionStreamSubscription?.cancel();
        _positionStreamSubscription = Geolocator.getPositionStream(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // Atualizar apenas a cada 10 metros
            timeLimit: const Duration(seconds: 10),
          ),
        ).listen(
          (Position position) {
            setState(() {
              _currentPosition = position;
            });
            _updateCurrentLocationMarker();
          },
          onError: (e) {
            print("Erro no stream de localização: $e");
          },
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error getting location: $e");
      // Se falhar em obter a localização, pelo menos mostrar os postos
      _addMarkers();
    }
  }

  void _updateCurrentLocationMarker() {
    if (_currentPosition == null) return;

    // Remover marcador antigo da localização atual
    _markers.removeWhere(
        (marker) => marker.markerId == const MarkerId('current_location'));

    // Adicionar novo marcador com a posição atualizada
    _markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position:
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        infoWindow: const InfoWindow(title: 'Sua localização atual'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        zIndex: 2, // Garantir que fique acima dos outros marcadores
      ),
    );

    setState(() {});
  }

  void _addMarkers() {
    // Limpar marcadores existentes
    _markers.clear();

    // Adicionar marcador para posição atual
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: const InfoWindow(title: 'Sua localização atual'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          zIndex: 2, // Garantir que fique acima dos outros marcadores
        ),
      );
    }

    // Adicionar marcadores para os postos de saúde (mesmo sem localização do usuário)
    for (var posto in _postosList) {
      _markers.add(
        Marker(
          markerId: MarkerId(posto['id']),
          position: LatLng(posto['latitude'], posto['longitude']),
          infoWindow: InfoWindow(
            title: posto['nome'],
            snippet: '${posto['rua']}, ${posto['numero']} - ${posto['bairro']}',
          ),
          icon: _healthPostIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          onTap: () {
            _showPostoDetails(posto);
          },
          zIndex: 1,
        ),
      );
    }

    // Se não tiver localização, centralizar no primeiro posto
    if (_currentPosition == null &&
        _postosList.isNotEmpty &&
        _mapController != null) {
      final firstPosto = _postosList.first;
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(firstPosto['latitude'], firstPosto['longitude']),
          12.0,
        ),
      );
    }

    setState(() {});
  }

  void _showPostoDetails(Map<String, dynamic> posto) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
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
                  posto['nome'],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0080FF),
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.location_on,
                  '${posto['rua']}, ${posto['numero']}',
                ),
                _buildInfoRow(Icons.location_city, posto['bairro']),
                if (posto['telefone'].isNotEmpty)
                  _buildInfoRow(Icons.phone, posto['telefone']),
                if (posto['linhas_onibus'].isNotEmpty)
                  _buildInfoRow(
                    Icons.directions_bus,
                    'Linhas de ônibus: ${posto['linhas_onibus']}',
                  ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(posto['latitude'], posto['longitude']),
                        16.0,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Ver no mapa'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF0080FF),
                  ),
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
          Icon(icon, color: const Color(0xFF0080FF), size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissão de Localização Necessária'),
        content: const Text(
          'Para visualizar os postos de saúde próximos e sua localização no mapa, é necessário conceder permissão de acesso à localização do dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0080FF),
            ),
            child: const Text('Abrir Configurações'),
          ),
        ],
      ),
    );
  }

  void _showLocationServiceDisabledDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Serviço de Localização Desativado'),
        content: const Text(
          'Para utilizar o mapa e ver sua localização, ative o serviço de localização no seu dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultLocation =
        const LatLng(-3.7480523, -38.5676128); // Fortaleza, CE

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Postos de Saúde'),
        backgroundColor: const Color(0xFF0080FF),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Envolver o GoogleMap em um try-catch visual usando Builder
          Builder(
            builder: (context) {
              try {
                return GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition != null
                        ? LatLng(_currentPosition!.latitude,
                            _currentPosition!.longitude)
                        : defaultLocation,
                    zoom: 14.0,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  mapToolbarEnabled: true,
                  compassEnabled: true,
                  markers: _markers,
                  onMapCreated: (controller) {
                    setState(() {
                      _mapController = controller;
                      if (!_isLoading && _markers.isEmpty) {
                        _addMarkers();
                      }
                    });
                  },
                );
              } catch (e) {
                // Tratamento visual para quando o mapa falhar completamente
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_off,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Não foi possível carregar o mapa',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          'Verifique sua conexão ou tente novamente mais tarde.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Exibir a lista de postos em formato de lista em vez do mapa
                          _showPostsListView();
                        },
                        icon: const Icon(Icons.list),
                        label: const Text('Ver lista de postos'),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0080FF)),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: "btn1",
            onPressed: () {
              _mapController?.animateCamera(
                CameraUpdate.zoomIn(),
              );
            },
            backgroundColor: const Color(0xFF0080FF),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: "btn2",
            onPressed: () {
              _mapController?.animateCamera(
                CameraUpdate.zoomOut(),
              );
            },
            backgroundColor: const Color(0xFF0080FF),
            child: const Icon(Icons.remove, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "btn3",
            onPressed: () {
              if (_currentPosition != null && _mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(_currentPosition!.latitude,
                        _currentPosition!.longitude),
                    16.0,
                  ),
                );
              } else {
                _getCurrentLocation();
              }
            },
            backgroundColor: const Color(0xFF0080FF),
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // Método para mostrar a lista de postos quando o mapa falhar
  void _showPostsListView() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Postos de Saúde',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF0080FF),
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _postosList.length,
                itemBuilder: (context, index) {
                  final posto = _postosList[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_hospital,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(posto['nome']),
                      subtitle: Text(
                          '${posto['rua']}, ${posto['numero']} - ${posto['bairro']}'),
                      onTap: () => _showPostoDetails(posto),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
