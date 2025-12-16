import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
  
  // Coordenadas por defecto (Puerto Montt)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(-41.469, -72.942), 
    zoom: 12,
  );

  Activity? _selectedActivity;

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
              
              // --- CORRECCIÓN: Usamos newLatLng para centrar el pin ---
              _mapController.animateCamera(
                CameraUpdate.newLatLng(
                  LatLng(activity.lat, activity.lng),
                ),
              );
            },
            icon: BitmapDescriptor.defaultMarker,
          );
        }).toSet();

        return Scaffold(
          body: Stack(
            children: [
              // 1. EL MAPA
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
                // Le damos padding abajo para que el logo de Google no quede tapado por la tarjeta
                padding: const EdgeInsets.only(bottom: 150), 
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                },
                onTap: (_) {
                  if (_selectedActivity != null) {
                    setState(() {
                      _selectedActivity = null;
                    });
                  }
                },
              ),

              // 2. BOTÓN DE RE-CENTRAR
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                top: 60, // Ajustado para que no choque con el notch
                right: 20,
                child: FloatingActionButton(
                  heroTag: 'recenter_map_btn',
                  mini: true,
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFF97316),
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

              // 3. TARJETA DE INFORMACIÓN (Mini Recuadro)
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
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Imagen
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                            ),
                            child: Image.network(
                              _selectedActivity!.imageUrl.isNotEmpty 
                                  ? _selectedActivity!.imageUrl 
                                  : 'https://via.placeholder.com/150',
                              width: 110,
                              height: 110,
                              fit: BoxFit.cover,
                            ),
                          ),
                          
                          // Info
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
                                      color: Color(0xFFF97316),
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
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat('d MMM, h:mm a').format(_selectedActivity!.dateTime),
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
                            child: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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