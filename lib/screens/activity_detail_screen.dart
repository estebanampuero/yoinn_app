import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/activity_model.dart';
import '../models/user_model.dart';
import '../services/data_service.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';
import 'edit_activity_screen.dart';
import 'profile_screen.dart'; 

class ActivityDetailScreen extends StatefulWidget {
  final Activity activity;

  const ActivityDetailScreen({super.key, required this.activity});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  bool _isJoining = false;

  void _joinActivity() async {
    setState(() => _isJoining = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final dataService = Provider.of<DataService>(context, listen: false);
    final user = authService.currentUser;

    if (user != null) {
      try {
        final userModel = await dataService.getUserProfile(user.uid);
        if (userModel != null) {
          await dataService.applyToActivity(widget.activity.id, userModel);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Solicitud enviada al anfitrión")),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error al unirse: $e")),
          );
        }
      }
    }
    if (mounted) setState(() => _isJoining = false);
  }

  void _showOptions(BuildContext context, bool isHost) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isHost)
                 ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text("Editar Actividad"),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => EditActivityScreen(activity: widget.activity)));
                  },
                ),
              
              if (!isHost)
                ListTile(
                  leading: const Icon(Icons.flag, color: Colors.red),
                  title: const Text("Reportar Actividad"),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showReportDialog();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showReportDialog() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reportar"),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: "¿Por qué reportas esto?"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              final user = Provider.of<AuthService>(context, listen: false).currentUser;
              if (user != null) {
                await Provider.of<DataService>(context, listen: false).reportContent(
                  reporterUid: user.uid,
                  reportedId: widget.activity.id,
                  type: 'activity',
                  reason: reasonController.text
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reporte enviado. Gracias.")));
              }
            },
            child: const Text("Enviar"),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthService>(context).currentUser;
    final isHost = currentUser?.uid == widget.activity.hostUid;
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(widget.activity.dateTime);
    final timeStr = DateFormat('h:mm a').format(widget.activity.dateTime);

    // --- CÁLCULO DE CUPOS ---
    final spotsLeft = widget.activity.maxAttendees - widget.activity.acceptedCount;
    final isFull = spotsLeft <= 0;
    
    final spotsColor = spotsLeft <= 2 ? Colors.red : Colors.green;
    final spotsText = isFull 
        ? "¡Actividad Llena!" 
        : "Quedan $spotsLeft cupos disponibles";

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: widget.activity.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.activity.imageUrl,
                      fit: BoxFit.cover,
                    )
                  : Image.network('https://via.placeholder.com/400x300', fit: BoxFit.cover),
            ),
            actions: [
               IconButton(
                icon: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.more_vert, color: Colors.black)),
                onPressed: () => _showOptions(context, isHost),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categoría
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F7FA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.activity.category.toUpperCase(),
                      style: const TextStyle(color: Color(0xFF006064), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Título
                  Text(
                    widget.activity.title,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF006064)),
                  ),
                  const SizedBox(height: 20),

                  // --- FILA DEL ORGANIZADOR ---
                  FutureBuilder<UserModel?>(
                    future: Provider.of<DataService>(context, listen: false).getUserProfile(widget.activity.hostUid),
                    builder: (context, snapshot) {
                      final host = snapshot.data;
                      if (host == null) return const SizedBox();

                      final isPro = host.activitiesCreatedCount > 5;
                      
                      return InkWell(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(uid: host.uid)));
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: isPro ? Border.all(color: Colors.amber, width: 2) : null,
                              ),
                              child: CircleAvatar(
                                radius: 22,
                                backgroundImage: host.profilePictureUrl.isNotEmpty 
                                    ? NetworkImage(host.profilePictureUrl) 
                                    : null,
                                child: host.profilePictureUrl.isEmpty ? const Icon(Icons.person) : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      host.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    if (host.isVerified) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.verified, color: Colors.blue, size: 16),
                                    ]
                                  ],
                                ),
                                const Text("Organizador", style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                            const Spacer(),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),

                  // Fecha y Hora
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.calendar_today, color: Colors.orange),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(timeStr, style: TextStyle(color: Colors.grey[600])),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Ubicación
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.location_on, color: Colors.blue),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.activity.location, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Text("Ubicación del evento", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.map, color: Colors.blue),
                        onPressed: () async {
                           final googleUrl = 'http://maps.google.com/maps?q=${widget.activity.lat},${widget.activity.lng}';
                           if (await canLaunchUrl(Uri.parse(googleUrl))) {
                             await launchUrl(Uri.parse(googleUrl));
                           }
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- CUPOS DISPONIBLES ---
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: spotsColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.people, color: spotsColor),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            spotsText, 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: spotsColor)
                          ),
                          Text(
                            "Capacidad total: ${widget.activity.maxAttendees} personas", 
                            style: const TextStyle(color: Colors.grey, fontSize: 12)
                          ),
                        ],
                      )
                    ],
                  ),

                  const SizedBox(height: 24),
                  
                  // Descripción
                  const Text("Sobre la actividad", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    widget.activity.description,
                    style: TextStyle(fontSize: 16, color: Colors.grey[800], height: 1.5),
                  ),
                  
                  const SizedBox(height: 100), // Espacio para el botón flotante
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: FutureBuilder<String?>(
            future: currentUser != null 
                ? Provider.of<DataService>(context, listen: false).getApplicationStatus(widget.activity.id, currentUser.uid)
                : Future.value(null),
            builder: (context, snapshot) {
              final status = snapshot.data;

              // Botón para el HOST
              if (isHost) {
                 return SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF00BCD4), width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        // --- CORRECCIÓN AQUÍ: Pasamos el objeto activity completo ---
                        MaterialPageRoute(builder: (context) => ChatScreen(
                          activity: widget.activity
                        )),
                      );
                    },
                    child: const Text("Ir al Chat del Grupo", style: TextStyle(fontSize: 16, color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                  ),
                );
              }

              // Botón si ya fue aceptado
              if (status == 'accepted') {
                return SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                       Navigator.push(
                        context,
                        // --- CORRECCIÓN AQUÍ: Pasamos el objeto activity completo ---
                        MaterialPageRoute(builder: (context) => ChatScreen(
                          activity: widget.activity
                        )),
                      );
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text("¡Estás dentro! Ir al Chat", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                );
              }

              // Botón si está pendiente
              if (status == 'pending') {
                return SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: null,
                    child: const Text("Solicitud enviada...", style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                );
              }

              // Botón para Unirse
              return SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFull ? Colors.grey : const Color(0xFF00BCD4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isFull ? null : (_isJoining ? null : _joinActivity),
                  child: _isJoining
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isFull ? "AGOTADO" : "Solicitar Unirme", 
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                        ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}