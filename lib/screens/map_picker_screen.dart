import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../services/location_service.dart';

class MapPickerScreen extends StatefulWidget {
  final bool isPro; 

  const MapPickerScreen({
    super.key, 
    this.isPro = false 
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(-41.469, -72.942); 
  String _address = "Ubicación seleccionada"; 
  bool _isLoadingAddress = false;
  bool _addressFetched = false; // Controla si ya tenemos la dirección real
  
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
    // Al inicio sí cargamos la dirección (1 llamada gratis del GPS inicial)
    _getAddressFromLatLng(latLng);
  }

  void _moveCamera(LatLng latLng) {
    setState(() {
      _center = latLng;
      _addressFetched = false; // Marcamos que necesitamos buscar dirección de nuevo si confirman
      // Mostramos coordenadas temporalmente mientras mueve, pero NO se guardarán
      _address = "${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}";
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
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
        
        // Si no hay calle, intentamos usar otros campos
        if (street.isEmpty) street = p.name ?? '';
        if (city.isEmpty) city = p.administrativeArea ?? '';

        setState(() {
          _address = "$street $number, $city".trim();
          // Limpieza de comas si faltan datos
          if (_address.startsWith(',')) _address = _address.substring(1).trim();
          _addressFetched = true;
        });
      }
    } catch (e) {
      print("Error obteniendo dirección: $e");
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  // --- CONFIRMACIÓN FINAL (AQUÍ ESTÁ LA MAGIA) ---
  Future<void> _confirmSelection() async {
    // 1. Si el usuario no ha buscado la dirección (solo movió el mapa),
    // la buscamos AHORA antes de cerrar.
    if (!_addressFetched) {
      await _getAddressFromLatLng(_center);
    }

    // 2. Devolvemos la dirección real (no las coordenadas)
    if (mounted) {
      Navigator.pop(context, {
        'lat': _center.latitude,
        'lng': _center.longitude,
        'address': _address // Ahora garantiza ser texto legible
      });
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
      final latLng = LatLng(lat, lng);
      
      _moveCamera(latLng);
      // Si buscó explícitamente, traemos la dirección de inmediato
      _getAddressFromLatLng(latLng); 
      _sessionToken = _uuid.v4();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, 
      body: Stack(
        children: [
          // 1. MAPA
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 15),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: (position) {
              // Solo actualizamos visualmente, sin gastar API
              setState(() {
                _center = position.target;
                _addressFetched = false; 
                _address = "${_center.latitude.toStringAsFixed(4)}, ${_center.longitude.toStringAsFixed(4)}";
              });
            },
          ),
          
          // 2. PIN CENTRAL
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40), 
              child: Icon(Icons.location_on, size: 50, color: Color(0xFFF97316)),
            ),
          ),

          // 3. BARRA DE BÚSQUEDA (PRO)
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Ubicación seleccionada:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        // Opción para ver la dirección antes de confirmar (Manual)
                        if (!_addressFetched && !_isLoadingAddress)
                          GestureDetector(
                            onTap: () => _getAddressFromLatLng(_center),
                            child: const Text("🔍 Ver dirección", style: TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.bold, fontSize: 12)),
                          )
                      ],
                    ),
                    const SizedBox(height: 5),
                    if (_isLoadingAddress)
                      const LinearProgressIndicator(color: Color(0xFFF97316))
                    else
                      Text(
                        // Aquí muestra coordenadas SI NO se ha hecho fetch, o Dirección SI YA se hizo
                        _address,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        // Llamamos a la nueva función _confirmSelection
                        onPressed: _isLoadingAddress ? null : _confirmSelection,
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