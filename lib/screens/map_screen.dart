import 'dart:ui' as ui; 
import 'package:flutter/services.dart'; 
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';

import '../models/activity_model.dart';
import '../services/data_service.dart';
import '../services/subscription_service.dart';
import '../services/auth_service.dart'; // <--- Agregado para validar usuario
import '../config/subscription_limits.dart';
import 'activity_detail_screen.dart';
import 'paywall_pro_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  BitmapDescriptor? _customPinIcon; 
  
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(-41.469, -72.942), // Default Puerto Montt
    zoom: 12,
  );

  Activity? _selectedActivity;
  bool _isPremium = false;
  LatLng? _currentCenter; 
  
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
    _checkPremiumAndLocation();
  }

  void _moveCameraSafe(CameraUpdate update) {
    if (_mapController != null && mounted) {
      try {
        _mapController!.animateCamera(update);
      } catch (e) {
        print("⚠️ Mapa no listo: $e");
      }
    }
  }

  Future<void> _checkPremiumAndLocation() async {
    // 1. Verificar Tienda (RevenueCat)
    bool isStorePro = await SubscriptionService.isUserPremium();
    bool isManualPro = false;

    // 2. Verificar Firebase (Manual PRO)
    if (mounted) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dataService = Provider.of<DataService>(context, listen: false);
      
      if (authService.currentUser != null) {
        final userProfile = await dataService.getUserProfile(authService.currentUser!.uid);
        isManualPro = userProfile?.isManualPro ?? false;
      }
    }

    // 3. Combinar resultados
    if (mounted) setState(() => _isPremium = isStorePro || isManualPro);

    // --- LÓGICA DE UBICACIÓN ---
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        final userPos = LatLng(position.latitude, position.longitude);
        
        if (mounted) {
          setState(() => _currentCenter = userPos);
          
          // Actualizamos DataService con la ubicación REAL
          final ds = Provider.of<DataService>(context, listen: false);
          ds.updateUserLocation(userPos.latitude, userPos.longitude);
          
          _moveCameraSafe(CameraUpdate.newLatLng(userPos));
        }
      }
    } catch (e) {
      print("Error GPS: $e");
    }
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  Future<void> _loadCustomMarker() async {
    try {
      final Uint8List markerIcon = await getBytesFromAsset('assets/icons/map_marker.png', 100);
      final icon = BitmapDescriptor.fromBytes(markerIcon);
      if (mounted) setState(() => _customPinIcon = icon);
    } catch (e) {
      print("Error loading marker: $e");
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
              setState(() => _selectedActivity = activity);
              _moveCameraSafe(CameraUpdate.newLatLng(LatLng(activity.lat, activity.lng)));
            },
            icon: _customPinIcon ?? BitmapDescriptor.defaultMarker,
          );
        }).toSet();

        Set<Circle> circles = {};
        if (_currentCenter != null) {
          circles.add(Circle(
            circleId: const CircleId('radiusParams'),
            center: _currentCenter!,
            radius: dataService.filterRadius * 1000, 
            fillColor: const Color(0xFF00BCD4).withOpacity(0.15), 
            strokeColor: const Color(0xFF00BCD4),
            strokeWidth: 1,
          ));
        }

        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              // 1. MAPA
              GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: _initialPosition,
                markers: markers,
                circles: circles,
                myLocationEnabled: true, // GPS siempre activo
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: false, 
                padding: const EdgeInsets.only(bottom: 120, top: 50),
                
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  _mapController?.setMapStyle(_mapStyle);
                  if (_currentCenter != null) {
                    _moveCameraSafe(CameraUpdate.newLatLng(_currentCenter!));
                  }
                },
                onTap: (_) {
                  if (_selectedActivity != null) setState(() => _selectedActivity = null);
                },
              ),

              // 2. BOTONES FLOTANTES (Recentrar)
              Positioned(
                top: 50, right: 20, 
                child: FloatingActionButton.small(
                  heroTag: 'recenter',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF00BCD4),
                  onPressed: _checkPremiumAndLocation,
                  child: const Icon(Icons.my_location),
                ),
              ),

              // 3. SLIDER DE DISTANCIA
              Positioned(
                bottom: 40, left: 20, 
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(children: [
                        const Icon(Icons.radar, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text("${dataService.filterRadius.toInt()} km", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF00BCD4)))
                      ]),
                      SizedBox(
                        width: 120, height: 20,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                          ),
                          child: Slider(
                            // Clamp para evitar error rojo si cambia de plan
                            value: dataService.filterRadius.clamp(
                              1.0, 
                              _isPremium ? SubscriptionLimits.proMaxRadius : SubscriptionLimits.freeMaxRadius
                            ),
                            min: 1,
                            // Aquí el máximo depende de la variable _isPremium que ahora se calcula correctamente
                            max: _isPremium ? SubscriptionLimits.proMaxRadius : SubscriptionLimits.freeMaxRadius,
                            activeColor: const Color(0xFF00BCD4),
                            inactiveColor: Colors.grey[200],
                            onChanged: (val) {
                              if (!_isPremium && val > SubscriptionLimits.freeMaxRadius) return;
                              dataService.setRadiusFilter(val);
                            },
                            onChangeEnd: (val) {
                              if (!_isPremium && val >= SubscriptionLimits.freeMaxRadius) {
                                 Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallProScreen()));
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. TARJETA DE ACTIVIDAD
              if (_selectedActivity != null)
                Positioned(
                  bottom: 20, left: 20, right: 20,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ActivityDetailScreen(activity: _selectedActivity!)));
                    },
                    child: Container(
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: const Color(0xFF00BCD4).withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                            child: CachedNetworkImage(
                              imageUrl: _selectedActivity!.imageUrl.isNotEmpty ? _selectedActivity!.imageUrl : 'https://via.placeholder.com/150',
                              width: 110, height: 110, fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(_selectedActivity!.category.toUpperCase(), style: const TextStyle(color: Color(0xFF29B6F6), fontSize: 10, fontWeight: FontWeight.bold)),
                                  Text(_selectedActivity!.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF006064)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text(DateFormat('d MMM, h:mm a', 'es_ES').format(_selectedActivity!.dateTime), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                          const Padding(padding: EdgeInsets.only(right: 12.0), child: Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF26C6DA))),
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