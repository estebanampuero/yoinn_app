import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../services/location_service.dart';

class MapPickerScreen extends StatefulWidget {
  final bool isPro; // <--- Nuevo parámetro recibido

  const MapPickerScreen({
    super.key, 
    this.isPro = false // Por defecto false
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(-41.469, -72.942); 
  String _address = "Mueve el mapa para seleccionar...";
  bool _isLoadingAddress = false;
  
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();
  List<PlacePrediction> _predictions = [];
  Timer? _debounce;
  final _uuid = const Uuid();
  late String _sessionToken;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _sessionToken = _uuid.v4();
    _determinePosition();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // --- LÓGICA DE MAPA Y GPS ---

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    final latLng = LatLng(position.latitude, position.longitude);
    
    _moveCamera(latLng);
  }

  void _moveCamera(LatLng latLng) {
    setState(() => _center = latLng);
    _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
    _getAddressFromLatLng(latLng);
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    setState(() => _isLoadingAddress = true);
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude
      );
      
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        String street = p.thoroughfare ?? '';
        String number = p.subThoroughfare ?? '';
        String city = p.locality ?? '';
        
        setState(() {
          _address = "$street $number, $city".trim();
          if (_address.startsWith(',')) _address = p.name ?? _address;
        });
      }
    } catch (e) {
      // Ignoramos errores momentáneos
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  // --- LÓGICA DE BÚSQUEDA ---

  void _onSearchChanged(String input) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (input.length > 2) {
        setState(() => _isSearching = true);
        final results = await _locationService.getPlacePredictions(input, _sessionToken);
        if (mounted) {
          setState(() {
            _predictions = results;
            _isSearching = false;
          });
        }
      } else {
        if (mounted) setState(() => _predictions = []);
      }
    });
  }

  Future<void> _selectPrediction(PlacePrediction prediction) async {
    setState(() {
      _predictions = [];
      _searchController.clear();
      FocusScope.of(context).unfocus();
    });

    final details = await _locationService.getPlaceDetails(prediction.placeId, _sessionToken);
    
    if (details != null) {
      final lat = details['lat'];
      final lng = details['lng'];
      _moveCamera(LatLng(lat, lng));
      _sessionToken = _uuid.v4();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, 
      body: Stack(
        children: [
          // 1. MAPA DE FONDO
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 15),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: (position) {
              _center = position.target;
            },
            onCameraIdle: () {
              _getAddressFromLatLng(_center);
            },
          ),
          
          // 2. PIN CENTRAL FIJO
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40), 
              child: Icon(Icons.location_on, size: 50, color: Color(0xFFF97316)),
            ),
          ),

          // 3. BARRA DE BÚSQUEDA Y BOTÓN ATRÁS (Condicional para PRO)
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.3), Colors.transparent],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Botón Atrás (Siempre visible)
                            Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black26)],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.black),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const SizedBox(width: 10),
                            
                            // Buscador (SOLO SI ES PRO)
                            if (widget.isPro) 
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 2))
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: _onSearchChanged,
                                    decoration: InputDecoration(
                                      hintText: "Buscar dirección...",
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                      suffixIcon: _isSearching 
                                        ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                                        : IconButton(
                                            icon: const Icon(Icons.clear, color: Colors.grey),
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() => _predictions = []);
                                            },
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        
                        // Lista de Resultados (Solo si hay texto y es PRO)
                        if (widget.isPro && _predictions.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 8, left: 50), 
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                            ),
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: _predictions.length,
                              separatorBuilder: (ctx, i) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final place = _predictions[index];
                                return ListTile(
                                  leading: const Icon(Icons.location_on_outlined, color: Colors.grey),
                                  title: Text(place.description, style: const TextStyle(fontSize: 14)),
                                  dense: true,
                                  onTap: () => _selectPrediction(place),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 4. BOTÓN GPS
          Positioned(
            bottom: 180,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'gps_btn',
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Color(0xFFF97316)),
              onPressed: _determinePosition,
            ),
          ),

          // 5. TARJETA INFERIOR (Confirmar)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Ubicación seleccionada:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 5),
                    if (_isLoadingAddress)
                      const LinearProgressIndicator(color: Color(0xFFF97316))
                    else
                      Text(
                        _address,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoadingAddress ? null : () {
                          Navigator.pop(context, {
                            'lat': _center.latitude,
                            'lng': _center.longitude,
                            'address': _address
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF97316),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("Confirmar Ubicación", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}