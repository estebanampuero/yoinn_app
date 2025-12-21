import 'dart:ui' as ui; // <--- NECESARIO PARA REDIMENSIONAR
import 'package:flutter/services.dart'; // <--- NECESARIO PARA LEER ASSETS
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/activity_model.dart';
import '../services/data_service.dart';
import 'activity_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  BitmapDescriptor? _customPinIcon; 
  
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(-41.469, -72.942), 
    zoom: 12,
  );

  Activity? _selectedActivity;

  // --- ESTILO DEL MAPA (JSON) ---
  // Esto apaga los POIs (Negocios) y el Transit (Transporte) para limpiar el mapa
  final String _mapStyle = '''
    [
      {
        "featureType": "poi",
        "stylers": [
          { "visibility": "off" }
        ]
      },
      {
        "featureType": "transit",
        "stylers": [
          { "visibility": "off" }
        ]
      }
    ]
  ''';

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
  }

  // --- FUNCIÓN MÁGICA PARA REDIMENSIONAR ---
  // Esta función toma tu imagen grande y la devuelve pequeña (width: 100)
  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  // Cargar el pin personalizado REDIMENSIONADO
  Future<void> _loadCustomMarker() async {
    try {
      // 100 es un buen tamaño para el mapa
      final Uint8List markerIcon = await getBytesFromAsset('assets/icons/map_marker.png', 100);
      
      final icon = BitmapDescriptor.fromBytes(markerIcon);
      
      setState(() {
        _customPinIcon = icon;
      });
    } catch (e) {
      print("Error cargando icono del mapa: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(
      builder: (context, dataService, child) {
        
        final Set<Marker> markers = dataService.activities.map((activity) {
          return Marker(
            markerId: MarkerId(activity.id),
            position: LatLng(activity.lat, activity.lng),
            onTap: () {
              setState(() {
                _selectedActivity = activity;
              });
              
              _mapController.animateCamera(
                CameraUpdate.newLatLng(
                  LatLng(activity.lat, activity.lng),
                ),
              );
            },
            // Usamos el icono cargado
            icon: _customPinIcon ?? BitmapDescriptor.defaultMarker,
          );
        }).toSet();

        return Scaffold(
          body: Stack(
            children: [
              GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: _initialPosition,
                markers: markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                scrollGesturesEnabled: true,
                zoomGesturesEnabled: true,
                tiltGesturesEnabled: true,
                rotateGesturesEnabled: true,
                compassEnabled: true,
                padding: const EdgeInsets.only(bottom: 150), 
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  // APLICAMOS EL ESTILO AQUÍ
                  _mapController.setMapStyle(_mapStyle);
                },
                onTap: (_) {
                  if (_selectedActivity != null) {
                    setState(() {
                      _selectedActivity = null;
                    });
                  }
                },
              ),

              // Botón Recentrar (Color Cian)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                top: 60, 
                right: 20,
                child: FloatingActionButton(
                  heroTag: 'recenter_map_btn',
                  mini: true,
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF00BCD4), // Cian
                  onPressed: () {
                     if (dataService.activities.isNotEmpty) {
                       final first = dataService.activities.first;
                       _mapController.animateCamera(
                         CameraUpdate.newLatLngZoom(LatLng(first.lat, first.lng), 13),
                       );
                     }
                  },
                  child: const Icon(Icons.center_focus_strong),
                ),
              ),

              // Tarjeta Flotante
              if (_selectedActivity != null)
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ActivityDetailScreen(activity: _selectedActivity!),
                        ),
                      );
                    },
                    child: Container(
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00BCD4).withOpacity(0.2), // Sombra cian
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: _selectedActivity!.imageUrl.isNotEmpty 
                                  ? _selectedActivity!.imageUrl 
                                  : 'https://via.placeholder.com/150',
                              width: 110,
                              height: 110,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: const Color(0xFFE0F7FA),
                                child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00BCD4)))
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image, color: Colors.grey)
                              ),
                            ),
                          ),
                          
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _selectedActivity!.category.toUpperCase(),
                                    style: const TextStyle(
                                      color: Color(0xFF29B6F6), // Azul Brillante
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedActivity!.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF006064),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 12, color: Color(0xFF26C6DA)),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat('d MMM, h:mm a', 'es_ES').format(_selectedActivity!.dateTime),
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const Padding(
                            padding: EdgeInsets.only(right: 12.0),
                            child: Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF26C6DA)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}