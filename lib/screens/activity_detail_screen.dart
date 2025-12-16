import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart'; // <--- IMPORTANTE
import '../models/activity_model.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import 'manage_activity_screen.dart'; 
import 'chat_screen.dart';
import 'edit_activity_screen.dart';

class ActivityDetailScreen extends StatefulWidget {
  final Activity activity;

  const ActivityDetailScreen({super.key, required this.activity});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  String? _myStatus; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user != null) {
      final status = await Provider.of<DataService>(context, listen: false)
          .getApplicationStatus(widget.activity.id, user.uid);
      
      if (mounted) {
        setState(() {
          _myStatus = status;
          _isLoading = false;
        });
      }
    } else {
       if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleApply() async {
    setState(() => _isLoading = true);
    try {
      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      if (user != null) {
        await Provider.of<DataService>(context, listen: false)
            .applyToActivity(widget.activity.id, user);
        await _checkStatus(); 
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Solicitud enviada!')),
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _isLoading = false);
    }
  }

  // --- LÓGICA DE GESTIÓN (Solo Host) ---
  void _showHostOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text("Editar Actividad"),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EditActivityScreen(activity: widget.activity)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.people, color: Colors.orange),
                title: const Text("Gestionar Participantes"),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ManageActivityScreen(activity: widget.activity)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Eliminar Actividad"),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("¿Eliminar actividad?"),
        content: const Text("Esta acción no se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); 
              await Provider.of<DataService>(context, listen: false).deleteActivity(widget.activity.id);
              if (mounted) Navigator.pop(context); 
            }, 
            child: const Text("Eliminar", style: TextStyle(color: Colors.red))
          ),
        ],
      )
    );
  }

  void _shareActivity() {
    final date = DateFormat('dd/MM/yyyy').format(widget.activity.dateTime);
    Share.share(
      '¡Únete a mi actividad en Yoinn!\n\n'
      '${widget.activity.title}\n'
      '📅 $date\n'
      '📍 ${widget.activity.location}\n\n'
      'Descarga la app para unirte.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthService>(context).currentUser;
    final isHost = currentUser?.uid == widget.activity.hostUid;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            actions: [
              IconButton(
                icon: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.share, color: Color(0xFFF97316), size: 20),
                ),
                onPressed: _shareActivity,
              ),
              const SizedBox(width: 8),
              
              if (isHost || _myStatus == 'accepted')
                IconButton(
                  icon: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.chat, color: Color(0xFFF97316), size: 20),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(activity: widget.activity),
                      ),
                    );
                  },
                ),
               const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.activity.title,
                style: const TextStyle(
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 10)],
                  fontSize: 16,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // --- IMAGEN DE CABECERA OPTIMIZADA ---
                  widget.activity.imageUrl.isNotEmpty 
                  ? CachedNetworkImage(
                      imageUrl: widget.activity.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[900]),
                    )
                  : Image.network('https://via.placeholder.com/400', fit: BoxFit.cover),

                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.activity.category.toUpperCase(),
                      style: const TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildInfoRow(
                    Icons.calendar_today, 
                    DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(widget.activity.dateTime)
                  ),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                    Icons.access_time, 
                    DateFormat('h:mm a').format(widget.activity.dateTime)
                  ),
                  const SizedBox(height: 10),
                  _buildInfoRow(Icons.location_on, widget.activity.location),

                  const SizedBox(height: 30),
                  const Text("Acerca de la actividad", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(
                    widget.activity.description,
                    style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                  ),
                  
                  const SizedBox(height: 24),
                  const Text("Ubicación", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  
                  SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(widget.activity.lat, widget.activity.lng),
                          zoom: 14,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('activityLoc'),
                            position: LatLng(widget.activity.lat, widget.activity.lng),
                          )
                        },
                        zoomControlsEnabled: false,
                        scrollGesturesEnabled: false,
                        zoomGesturesEnabled: false,
                        mapToolbarEnabled: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 100), 
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: _buildActionButton(isHost),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFF97316)),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
      ],
    );
  }

  Widget _buildActionButton(bool isHost) {
    if (_isLoading) {
      return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()));
    }

    if (isHost) {
      return ElevatedButton(
        onPressed: () => _showHostOptions(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[800],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text("Gestionar Actividad", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
      );
    }

    if (_myStatus == 'accepted') {
       return ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(activity: widget.activity),
            ),
          );
        },
        icon: const Icon(Icons.chat),
        label: const Text("Ir al Chat", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    if (_myStatus == 'pending') {
      return ElevatedButton(
        onPressed: null, 
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange[100],
          disabledBackgroundColor: Colors.orange[100],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text("Solicitud Pendiente", style: TextStyle(fontSize: 18, color: Colors.orange, fontWeight: FontWeight.bold)),
      );
    }

    return ElevatedButton(
      onPressed: _handleApply,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF97316),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text("Solicitar Unirse", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}