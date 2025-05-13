import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../viewmodels/location_viewmodel.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  late TextEditingController _searchController;
  late final MapController _mapController;
  late Position _currentPosition;
  late StreamSubscription<Position> _positionStream;
  LatLng? _searchedLocation;


  void _recenterMap() {
    if (_currentPosition.latitude != 0.0 && _currentPosition.longitude != 0.0) {
      _mapController.move(
        LatLng(_currentPosition.latitude, _currentPosition.longitude),
        16.0,
      );
    } else {
      _showSnackBar('Esperando ubicación...');
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _mapController = MapController();

    _currentPosition = Position(
      latitude: 0.0,
      longitude: 0.0,
      timestamp: DateTime.now(),
      accuracy: 10.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      altitudeAccuracy: 10.0,
      headingAccuracy: 10.0,
      speedAccuracy: 10.0,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final locationViewModel = Provider.of<LocationViewModel>(context, listen: false);
      await locationViewModel.fetchLocation();

      if (locationViewModel.location != null) {
        setState(() {
          _currentPosition = Position(
            latitude: locationViewModel.location!.latitude,
            longitude: locationViewModel.location!.longitude,
            timestamp: DateTime.now(),
            accuracy: 10.0,
            altitude: 0.0,
            heading: 0.0,
            speed: 0.0,
            altitudeAccuracy: 10.0,
            headingAccuracy: 10.0,
            speedAccuracy: 10.0,
          );
        });
      }
    });

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      setState(() {
        _currentPosition = position;
      });
    });
  }

  @override
  void dispose() {
    _positionStream
        .cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchAddress() async {
    final viewModel = Provider.of<LocationViewModel>(context, listen: false);
    final newLocation = await viewModel.searchAddress(_searchController.text);

    if (newLocation != null) {
      setState(() {
        _searchedLocation = newLocation;
      });
      _mapController.move(newLocation, 16.0);
    } else {
      _showSnackBar('Dirección no encontrada.');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<LocationViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final location = viewModel.location;

        if (location == null) {
          return const Scaffold(
            body: Center(
              child: Text(
                'No fue posible obtener la localización.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          );
        }

        return Scaffold(
          body: Stack(
            children: [
              // Mapa de fondo
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(
                    _currentPosition.latitude,
                    _currentPosition.longitude,
                  ),
                  initialZoom: 16,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.flutter_mapas_osm',
                  ),
                  MarkerLayer(
                    markers: [
                      // Marcador de la ubicación actual
                      Marker(
                        point: LatLng(_currentPosition.latitude, _currentPosition.longitude),
                        width: 50,
                        height: 50,
                        child: Semantics(
                          label: 'Tu ubicación actual',
                          child: const Icon(
                            Icons.location_on,
                            color: Color(0xFF6373A6),
                            size: 50,
                          ),
                        ),
                      ),
                      // Si hay una ubicación buscada, agrega un marcador allí
                      if (_searchedLocation != null)
                        Marker(
                          point: _searchedLocation!,
                          width: 50,
                          height: 50,
                          child: Semantics(
                            label: 'Ubicación buscada',
                            child: const Icon(
                              Icons.location_on,
                              color: Color(0xFF6373A6),
                              size: 50,
                            ),
                          ),
                        ),
                    ],
                  )
                ],
              ),

              // Barra de búsqueda encima del mapa
              Positioned(
                top: 40,
                left: 16,
                right: 16,
                child: Center(
                  child: Semantics(
                    label: 'Buscar dirección',
                    hint: 'Introduce una dirección y pulsa el botón de búsqueda',
                    textField: true,
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Buscar dirección',
                            border: InputBorder.none,
                            suffixIcon: Semantics(
                              label: 'Buscar',
                              hint: 'Presiona para buscar dirección',
                              button: true,
                              child: IconButton(
                                icon: const Icon(Icons.search, color: Color(0xFF6373A6),),
                                onPressed: _searchAddress,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Botón para recentrar mapa
              Positioned(
                bottom: 20,
                right: 20,
                child: Semantics(
                  label: 'Ubicación actual',
                  hint: 'Presiona para centrar el mapa en tu ubicación',
                  button: true,
                  child: FloatingActionButton(
                    mini: true,
                    onPressed: _recenterMap,
                    child: const Icon(Icons.my_location, color: Color(0xFF6373A6)),
                  ),
                ),
              )
            ],
          ),
        );

      },
    );
  }
}
