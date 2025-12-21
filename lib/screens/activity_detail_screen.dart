import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart'; 
import '../models/activity_model.dart';
import '../models/user_model.dart';
import '../services/data_service.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';
import 'edit_activity_screen.dart';
import 'profile_screen.dart';
import 'manage_requests_screen.dart'; // <--- NUEVO IMPORT

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

  // --- LÓGICA PARA ELIMINAR ACTIVIDAD ---
  void _mostrarConfirmacionEliminar(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text("Eliminar Actividad"),
          content: const Text("¿Estás seguro de que quieres eliminar esta actividad? Esta acción no se puede deshacer."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); 
                _eliminarActividad(); 
              },
              child: const Text(
                "Eliminar",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _eliminarActividad() async {
    final dataService = Provider.of<DataService>(context, listen: false);
    try {
      await dataService.deleteActivity(widget.activity.id); 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Actividad eliminada correctamente")),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al eliminar: $e")),
        );
      }
    }
  }

  // --- LÓGICA PARA COMPARTIR ---
  void _compartirActividad() {
    final String deepLink = 'https://yoinn.app/activity/${widget.activity.id}';
    final String mensaje = '¡Hola! Únete a mi actividad "${widget.activity.title}" en Yoinn. Mira los detalles aquí: $deepLink';
    Share.share(mensaje);
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
              ListTile(
                leading: const Icon(Icons.share, color: Colors.blue),
                title: const Text("Compartir Actividad"),
                onTap: () {
                  Navigator.pop(ctx);
                  _compartirActividad();
                },
              ),
              const Divider(),

              if (isHost) ...[
                 ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blueGrey),
                  title: const Text("Editar Actividad"),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => EditActivityScreen(activity: widget.activity)));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text("Eliminar Actividad", style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _mostrarConfirmacionEliminar(context);
                  },
                ),
              ],
              
              if (!isHost)
                ListTile(
                  leading: const Icon(Icons.flag, color: Colors.orange),
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
    final dataService = Provider.of<DataService>(context, listen: false);

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
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white, 
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero, 
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
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
                icon: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.share, color: Colors.black, size: 20)),
                onPressed: _compartirActividad,
              ),
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
                  
                  Text(
                    widget.activity.title,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF006064)),
                  ),
                  const SizedBox(height: 20),

                  FutureBuilder<UserModel?>(
                    future: dataService.getUserProfile(widget.activity.hostUid),
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

                  _buildDetailRow(Icons.calendar_today, Colors.orange, dateStr, timeStr),
                  const SizedBox(height: 16),
                  _buildDetailRow(Icons.location_on, Colors.blue, widget.activity.location, "Ubicación del evento", 
                    onTap: () async {
                       final googleUrl = 'http://googleusercontent.com/maps.google.com/?q=${widget.activity.lat},${widget.activity.lng}';
                       if (await canLaunchUrl(Uri.parse(googleUrl))) {
                         await launchUrl(Uri.parse(googleUrl));
                       }
                    },
                    isLink: true
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(Icons.people, spotsColor, spotsText, "Capacidad total: ${widget.activity.maxAttendees} personas"),

                  const SizedBox(height: 24),

                  const Text("Asistentes Confirmados", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  
                  StreamBuilder<QuerySnapshot>(
                    stream: dataService.getActivityApplications(widget.activity.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final acceptedDocs = snapshot.data?.docs.where((doc) => doc['status'] == 'accepted').toList() ?? [];

                      if (acceptedDocs.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text("Aún nadie se ha unido. ¡Sé el primero!", style: TextStyle(color: Colors.grey)),
                          ),
                        );
                      }

                      return SizedBox(
                        height: 70,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: acceptedDocs.length,
                          itemBuilder: (context, index) {
                            final data = acceptedDocs[index].data() as Map<String, dynamic>;
                            final name = data['applicantName'] ?? '';
                            final pic = data['applicantProfilePictureUrl'] ?? '';
                            final uid = data['applicantUid'] ?? '';

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(uid: uid)));
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12.0),
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundImage: pic.isNotEmpty ? NetworkImage(pic) : null,
                                      backgroundColor: Colors.blue[100],
                                      child: pic.isEmpty ? Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(fontWeight: FontWeight.bold)) : null,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      name.split(' ')[0], 
                                      style: const TextStyle(fontSize: 10),
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  const Text("Sobre la actividad", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    widget.activity.description,
                    style: TextStyle(fontSize: 16, color: Colors.grey[800], height: 1.5),
                  ),
                  
                  const SizedBox(height: 100), 
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
          // CAMBIO CLAVE: Usamos StreamBuilder en vez de FutureBuilder
          // para escuchar cambios en tiempo real (Unirse -> Pendiente -> Aceptado)
          child: StreamBuilder<QuerySnapshot>(
            stream: dataService.getActivityApplications(widget.activity.id),
            builder: (context, snapshot) {
              String? status;
              
              if (snapshot.hasData && currentUser != null) {
                // Buscamos si el usuario actual tiene una solicitud
                try {
                  final myDoc = snapshot.data!.docs.firstWhere((doc) => doc['applicantUid'] == currentUser.uid);
                  status = myDoc['status'];
                } catch (e) {
                  // No ha solicitado unirse aún
                  status = null; 
                }
              }

              // --- VISTA DEL DUEÑO (HOST) ---
              if (isHost) {
                 return Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     // Botón para ir al Chat
                     SizedBox(
                       width: double.infinity,
                       height: 45,
                       child: ElevatedButton(
                         style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.white,
                           side: const BorderSide(color: Color(0xFF00BCD4), width: 2),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                         ),
                         onPressed: () {
                           Navigator.push(
                             context,
                             MaterialPageRoute(builder: (context) => ChatScreen(
                               activity: widget.activity
                             )),
                           );
                         },
                         child: const Text("Ir al Chat del Grupo", style: TextStyle(fontSize: 16, color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                       ),
                     ),
                     const SizedBox(height: 12),
                     // Botón NUEVO para gestionar solicitudes
                     SizedBox(
                       width: double.infinity,
                       height: 45,
                       child: ElevatedButton.icon(
                         style: ElevatedButton.styleFrom(
                           backgroundColor: const Color(0xFF00BCD4),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                         ),
                         onPressed: () {
                           Navigator.push(
                             context,
                             MaterialPageRoute(builder: (context) => ManageRequestsScreen(
                               activityId: widget.activity.id,
                               activityTitle: widget.activity.title,
                             )),
                           );
                         },
                         icon: const Icon(Icons.people, color: Colors.white),
                         label: const Text("Gestionar Solicitudes", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                       ),
                     ),
                   ],
                 );
              }

              // --- VISTA DEL PARTICIPANTE ---
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

  Widget _buildDetailRow(IconData icon, Color color, String title, String subtitle, {VoidCallback? onTap, bool isLink = false}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          if (isLink)
             IconButton(icon: Icon(Icons.open_in_new, color: color, size: 20), onPressed: onTap),
        ],
      ),
    );
  }
}