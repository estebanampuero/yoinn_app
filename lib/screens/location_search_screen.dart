import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/location_service.dart';

class LocationSearchScreen extends StatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final _controller = TextEditingController();
  final _locationService = LocationService();
  final _uuid = const Uuid();
  late String _sessionToken;
  
  List<PlacePrediction> _predictions = [];
  Timer? _debounce;
  bool _isLoadingGPS = false;

  @override
  void initState() {
    super.initState();
    _sessionToken = _uuid.v4();
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String input) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (input.length > 2) {
        final results = await _locationService.getPlacePredictions(input, _sessionToken);
        setState(() {
          _predictions = results;
        });
      } else {
        setState(() => _predictions = []);
      }
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoadingGPS = true);
    
    final locationData = await _locationService.getCurrentLocation();
    
    setState(() => _isLoadingGPS = false);

    if (locationData != null && mounted) {
      Navigator.pop(context, locationData);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo obtener la ubicación GPS")),
      );
    }
  }

  Future<void> _selectPlace(String placeId) async {
    final details = await _locationService.getPlaceDetails(placeId, _sessionToken);
    if (details != null && mounted) {
      Navigator.pop(context, details);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Buscar dirección...",
            border: InputBorder.none,
          ),
          onChanged: _onSearchChanged,
        ),
      ),
      body: Column(
        children: [
          // Botón GPS
          ListTile(
            leading: _isLoadingGPS 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              : const CircleAvatar(
                  backgroundColor: Color(0xFFF97316),
                  radius: 16,
                  child: Icon(Icons.my_location, color: Colors.white, size: 18),
                ),
            title: const Text("Usar mi ubicación actual", style: TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.bold)),
            onTap: _isLoadingGPS ? null : _useCurrentLocation,
          ),
          const Divider(height: 1),
          
          // Lista de resultados
          Expanded(
            child: ListView.separated(
              itemCount: _predictions.length,
              separatorBuilder: (ctx, i) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final place = _predictions[index];
                return ListTile(
                  leading: const Icon(Icons.location_on_outlined, color: Colors.grey),
                  title: Text(place.description),
                  onTap: () => _selectPlace(place.placeId),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}