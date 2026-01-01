import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

// Tu API Key
const String GOOGLE_API_KEY = "AIzaSyDiAUkUBYs3xjQOF3ME7AOv8KI5Oi_8psw"; 

class PlacePrediction {
  final String description;
  final String placeId;

  PlacePrediction({required this.description, required this.placeId});

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      description: json['description'],
      placeId: json['place_id'],
    );
  }
}

class LocationService {
  
  // Obtener sugerencias de autocompletado
  Future<List<PlacePrediction>> getPlacePredictions(String input, String sessionToken) async {
    if (input.isEmpty) return [];

    // Restringimos a Chile (components=country:cl) para mejores resultados
    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$GOOGLE_API_KEY&sessiontoken=$sessionToken&components=country:cl';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final predictions = data['predictions'] as List;
        return predictions.map((p) => PlacePrediction.fromJson(p)).toList();
      }
    }
    return [];
  }

  // Obtener detalles (Lat/Lng) a partir de un Place ID
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId, String sessionToken) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry,formatted_address&key=$GOOGLE_API_KEY&sessiontoken=$sessionToken';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final result = data['result'];
        final location = result['geometry']['location'];
        return {
          'lat': location['lat'],
          'lng': location['lng'],
          'address': result['formatted_address']
        };
      }
    }
    return null;
  }

  // Obtener ubicación actual del GPS
  Future<Map<String, dynamic>?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    
    if (permission == LocationPermission.deniedForever) return null;

    final position = await Geolocator.getCurrentPosition();
    
    // Obtener dirección legible (Geocoding inverso)
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        // Construir dirección bonita: Calle 123, Ciudad
        String address = "${p.thoroughfare ?? ''} ${p.subThoroughfare ?? ''}, ${p.locality ?? ''}".trim();
        
        // CORRECCIÓN: Usamos un fallback técnico en inglés para no forzar español
        if (address == ",") address = "Current Location"; 
        
        return {
          'lat': position.latitude,
          'lng': position.longitude,
          'address': address
        };
      }
    } catch (e) {
      print("Error geocoding: $e");
    }

    // CORRECCIÓN: Fallback en inglés
    return {
      'lat': position.latitude,
      'lng': position.longitude,
      'address': "Current Location" 
    };
  }
}