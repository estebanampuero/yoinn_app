import 'dart:ui' as ui; 
import 'package:flutter/services.dart'; 
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import 'package:custom_info_window/custom_info_window.dart'; 
import 'package:yoinn_app/l10n/app_localizations.dart'; 

import '../models/activity_model.dart';
import '../services/data_service.dart';
import '../services/subscription_service.dart';
import '../services/auth_service.dart'; 
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
  final CustomInfoWindowController _customInfoWindowController = CustomInfoWindowController(); 
  BitmapDescriptor? _customPinIcon; 
  
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(-41.469, -72.942), 
    zoom: 12,
  );

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

  @override
  void dispose() {
    _customInfoWindowController.dispose();
    super.dispose();
  }

  String _getCategoryName(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'Deportes': return l10n.catSport;
      case 'Comida': return l10n.catFood;
      case 'Arte': return l10n.catArt;
      case 'Fiesta': return l10n.catParty; 
      case 'Viajes': return l10n.catOutdoor; 
      case 'Musica': return l10n.hobbyMusic;
      case 'Tecnología': return l10n.hobbyTech;
      case 'Bienestar': return l10n.hobbyWellness;
      case 'Otros': return l10n.catOther;
      default: return key; 
    }
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
    bool isStorePro = await SubscriptionService.isUserPremium();
    bool isManualPro = false;

    if (mounted) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dataService = Provider.of<DataService>(context, listen: false);
      
      if (authService.currentUser != null) {
        final userProfile = await dataService.getUserProfile(authService.currentUser!.uid);
        isManualPro = userProfile?.isManualPro ?? false;
      }
    }

    if (mounted) setState(() => _isPremium = isStorePro || isManualPro);

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
    final l10n = AppLocalizations.of(context)!;

    return Consumer<DataService>(
      builder: (context, dataService, child) {
        
        final Set<Marker> markers = dataService.activities.map((activity) {
          return Marker(
            markerId: MarkerId(activity.id),
            position: LatLng(activity.lat, activity.lng),
            icon: _customPinIcon ?? BitmapDescriptor.defaultMarker,
            onTap: () {
              // --- ANIMACIÓN "POP" DESDE EL PIN ---
              _customInfoWindowController.addInfoWindow!(
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack, // Efecto de rebote suave al salir
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      alignment: Alignment.bottomCenter, // Crece desde la base (desde el pin)
                      child: child,
                    );
                  },
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ActivityDetailScreen(activity: activity)));
                    },
                    child: Column(
                      children: [
                        // CONTENEDOR PRINCIPAL (CARD)
                        Container(
                          width: 240, 
                          height: 90, 
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))
                            ],
                          ),
                          child: Row(
                            children: [
                              // IMAGEN
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: activity.imageUrl.isNotEmpty ? activity.imageUrl : 'https://via.placeholder.com/150',
                                  width: 70, height: 70, fit: BoxFit.cover,
                                  errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, size: 20, color: Colors.grey)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // TEXTOS
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _getCategoryName(context, activity.category).toUpperCase(), 
                                      style: const TextStyle(color: Color(0xFF29B6F6), fontSize: 9, fontWeight: FontWeight.bold)
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      activity.title, 
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF006064)), 
                                      maxLines: 1, 
                                      overflow: TextOverflow.ellipsis
                                    ),
                                    Text(
                                      DateFormat('d MMM, h:mm a', Localizations.localeOf(context).toString()).format(activity.dateTime), 
                                      style: const TextStyle(fontSize: 10, color: Colors.grey)
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // TRIANGULO (COLITA) - Con sombra simulada si se desea, aquí simple
                        ClipPath(
                          clipper: _TriangleClipper(),
                          child: Container(
                            color: Colors.white,
                            width: 20,
                            height: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                LatLng(activity.lat, activity.lng),
              );
            },
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
                myLocationEnabled: true, 
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: false, 
                padding: const EdgeInsets.only(bottom: 20, top: 50),
                
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  _customInfoWindowController.googleMapController = controller; 
                  _mapController?.setMapStyle(_mapStyle);
                  if (_currentCenter != null) {
                    _moveCameraSafe(CameraUpdate.newLatLng(_currentCenter!));
                  }
                },
                onTap: (position) {
                  _customInfoWindowController.hideInfoWindow!();
                },
                onCameraMove: (position) {
                  _customInfoWindowController.onCameraMove!();
                },
              ),

              // 2. LAYER DE LA BURBUJA FLOTANTE (Optimizado)
              CustomInfoWindow(
                controller: _customInfoWindowController,
                height: 110, 
                width: 240,
                offset: 35, // <--- AJUSTE CRÍTICO: Más cerca del pin (antes 50)
              ),

              // 3. BOTONES FLOTANTES (GPS)
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

              // 4. SLIDER DE DISTANCIA
              Positioned(
                bottom: 40, left: 20, 
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(children: [
                        const Icon(Icons.radar, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          "${dataService.filterRadius.toInt()} ${l10n.kmUnit}", 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF00BCD4))
                        )
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
                            value: dataService.filterRadius.clamp(
                              1.0, 
                              _isPremium ? SubscriptionLimits.proMaxRadius : SubscriptionLimits.freeMaxRadius
                            ),
                            min: 1,
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
            ],
          ),
        );
      },
    );
  }
}

// Clipper para la colita de la burbuja
class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}