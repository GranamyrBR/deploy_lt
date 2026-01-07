import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapsWidget extends StatefulWidget {
  final Map<String, dynamic>? coordinates;
  final Map<String, dynamic>? directions;
  final List<Map<String, dynamic>>? distanceMatrix;
  final Map<String, dynamic>? optimizedRoute;
  final double height;
  final String title;

  const GoogleMapsWidget({
    super.key,
    this.coordinates,
    this.directions,
    this.distanceMatrix,
    this.optimizedRoute,
    this.height = 300,
    this.title = 'Mapa',
  });

  @override
  State<GoogleMapsWidget> createState() => _GoogleMapsWidgetState();
}

class _GoogleMapsWidgetState extends State<GoogleMapsWidget> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  LatLng? _center;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void didUpdateWidget(GoogleMapsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coordinates != widget.coordinates ||
        oldWidget.directions != widget.directions ||
        oldWidget.distanceMatrix != widget.distanceMatrix ||
        oldWidget.optimizedRoute != widget.optimizedRoute) {
      _initializeMap();
    }
  }

  void _initializeMap() {
    _markers.clear();
    _polylines.clear();

    // Definir centro padrão (Nova York)
    _center = const LatLng(40.7128, -74.0060);

    // Adicionar marcador para coordenadas
    if (widget.coordinates != null) {
      final lat = widget.coordinates!['latitude'] as double;
      final lng = widget.coordinates!['longitude'] as double;
      _center = LatLng(lat, lng);
      
      _markers.add(
        Marker(
          markerId: const MarkerId('location'),
          position: _center!,
          infoWindow: const InfoWindow(
            title: 'Localização',
            snippet: 'Coordenadas encontradas',
          ),
        ),
      );
    }

    // Adicionar marcadores e rota para directions
    if (widget.directions != null) {
      _addDirectionsToMap();
    }

    // Adicionar marcadores para distance matrix
    if (widget.distanceMatrix != null) {
      _addDistanceMatrixToMap();
    }

    // Adicionar marcadores para rota otimizada
    if (widget.optimizedRoute != null) {
      _addOptimizedRouteToMap();
    }

    // Animar para o centro
    if (_mapController != null && _center != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_center!, 12),
      );
    }
  }

  void _addDirectionsToMap() {
    if (widget.directions == null) return;

    final directions = widget.directions!;
    
    // Adicionar marcador de origem
    if (directions['start_location'] != null) {
      final start = directions['start_location'] as Map<String, dynamic>;
      _markers.add(
        Marker(
          markerId: const MarkerId('origin'),
          position: LatLng(start['lat'], start['lng']),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Origem',
            snippet: directions['start_address'] ?? 'Ponto de partida',
          ),
        ),
      );
    }

    // Adicionar marcador de destino
    if (directions['end_location'] != null) {
      final end = directions['end_location'] as Map<String, dynamic>;
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(end['lat'], end['lng']),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Destino',
            snippet: directions['end_address'] ?? 'Ponto de chegada',
          ),
        ),
      );
    }

    // Adicionar rota
    if (directions['polyline'] != null) {
      final polyline = directions['polyline'] as Map<String, dynamic>;
      final points = _decodePolyline(polyline['points'] ?? '');
      
      if (points.isNotEmpty) {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: Colors.blue,
            width: 4,
          ),
        );
      }
    }
  }

  void _addDistanceMatrixToMap() {
    if (widget.distanceMatrix == null) return;

    for (int i = 0; i < widget.distanceMatrix!.length; i++) {
      final distance = widget.distanceMatrix![i];
      if (distance['location'] != null) {
        final location = distance['location'] as Map<String, dynamic>;
        _markers.add(
          Marker(
            markerId: MarkerId('distance_$i'),
            position: LatLng(location['lat'], location['lng']),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            infoWindow: InfoWindow(
              title: distance['name'] ?? 'Local $i',
              snippet: '${distance['distance']} - ${distance['duration']}',
            ),
          ),
        );
      }
    }
  }

  void _addOptimizedRouteToMap() {
    if (widget.optimizedRoute == null) return;

    final route = widget.optimizedRoute!;
    final attractions = route['attractions'] as List<dynamic>?;
    
    if (attractions != null) {
      for (int i = 0; i < attractions.length; i++) {
        final attraction = attractions[i] as Map<String, dynamic>;
        if (attraction['location'] != null) {
          final location = attraction['location'] as Map<String, dynamic>;
          _markers.add(
            Marker(
              markerId: MarkerId('optimized_$i'),
              position: LatLng(location['lat'], location['lng']),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
              infoWindow: InfoWindow(
                title: attraction['name'] ?? 'Atração $i',
                snippet: 'Ordem: ${i + 1}',
              ),
            ),
          );
        }
      }
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      final p = LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble());
      poly.add(p);
    }
    return poly;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.map, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: widget.height,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: _buildMapContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapContent() {
    // Verificar se está rodando no macOS
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.macOS) {
      return _buildMacOSAlternative();
    }
    
    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        if (_center != null) {
          controller.animateCamera(
            CameraUpdate.newLatLngZoom(_center!, 12),
          );
        }
      },
      initialCameraPosition: CameraPosition(
        target: _center ?? const LatLng(40.7128, -74.0060),
        zoom: 12,
      ),
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: true,
      mapToolbarEnabled: true,
    );
  }

  Widget _buildMacOSAlternative() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '🗺️ Mapa Interativo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Visualização disponível em dispositivos móveis',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                if (widget.coordinates != null) ...[
                  Text(
                    '📍 Coordenadas:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  Text(
                    '${widget.coordinates!['latitude']}, ${widget.coordinates!['longitude']}',
                    style: TextStyle(color: Colors.blue[600]),
                  ),
                ],
                if (widget.directions != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '🗺️ Rota:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  Text(
                    '${widget.directions!['distance']} em ${widget.directions!['duration']}',
                    style: TextStyle(color: Colors.blue[600]),
                  ),
                ],
                if (widget.distanceMatrix != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '📏 Distâncias:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  Text(
                    '${widget.distanceMatrix!.length} pontos calculados',
                    style: TextStyle(color: Colors.blue[600]),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              _openGoogleMapsWeb();
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Abrir no Google Maps'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _openGoogleMapsWeb() {
    String url = 'https://www.google.com/maps';
    
    if (widget.coordinates != null) {
      final lat = widget.coordinates!['latitude'];
      final lng = widget.coordinates!['longitude'];
      url = 'https://www.google.com/maps?q=$lat,$lng';
    } else if (widget.directions != null) {
      final start = widget.directions!['start_address'];
      final end = widget.directions!['end_address'];
      url = 'https://www.google.com/maps/dir/$start/$end';
    }
    
    // Abrir no navegador (funciona no macOS)
    // Nota: Para produção, você pode usar url_launcher
    debugPrint('Abrindo Google Maps: $url');
  }
} 
