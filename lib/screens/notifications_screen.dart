import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 
import 'package:yoinn_app/l10n/app_localizations.dart'; 

import '../services/data_service.dart';
import '../services/auth_service.dart';
import '../models/activity_model.dart';
import 'activity_detail_screen.dart';
import 'manage_requests_screen.dart';
import 'chat_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context, listen: false);
    final dataService = Provider.of<DataService>(context, listen: false);
    final uid = authService.currentUser?.uid;

    if (uid == null) return Center(child: Text(l10n.msgLoginToViewAlerts));

    return Scaffold(
      backgroundColor: Colors.white, // Fondo limpio minimalista
      appBar: AppBar(
        title: Text(
          l10n.screenNotificationsTitle, 
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 20)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false, // Alineado a la izquierda es más moderno en iOS/Android hoy día
        automaticallyImplyLeading: false, 
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[100], height: 1), // Separador sutil
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: dataService.getUserNotifications(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text(l10n.msgErrorLoadingNotifications));
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black));
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(l10n.msgNoNewNotifications, style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder( // Builder es más eficiente que separated aquí
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final notifId = doc.id;
              
              final title = data['title'] ?? l10n.lblNotificationDefaultTitle;
              final body = data['body'] ?? '';
              final type = data['type'] ?? 'info'; 
              final activityId = data['activityId'];
              final isRead = data['read'] ?? false;
              final timestamp = data['timestamp'] as Timestamp?;
              
              final timeStr = timestamp != null 
                  ? _formatTime(timestamp.toDate(), context)
                  : '';

              return Dismissible(
                key: Key(notifId),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  color: const Color(0xFFFF5252), // Rojo vibrante pero suave
                  padding: const EdgeInsets.only(right: 24),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (direction) {
                  FirebaseFirestore.instance.collection('users').doc(uid).collection('notifications').doc(notifId).delete();
                },
                child: InkWell(
                  onTap: () => _handleNotificationTap(context, dataService, uid, notifId, activityId, type, title),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isRead ? Colors.white : const Color(0xFFF5F9FF), // Azul muy muy pálido para no leídos
                      border: Border(bottom: BorderSide(color: Colors.grey[100]!)), // Línea divisoria ultra fina
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. INDICADOR DE TIPO (Minimalista: Punto o Icono pequeño sin fondo)
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: _buildTypeIndicator(type, isRead),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // 2. CONTENIDO
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      title, 
                                      style: TextStyle(
                                        fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                                        fontSize: 15,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1, 
                                      overflow: TextOverflow.ellipsis
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    timeStr, 
                                    style: TextStyle(
                                      fontSize: 12, 
                                      color: isRead ? Colors.grey[400] : const Color(0xFF00BCD4), // Color de marca si es nuevo
                                      fontWeight: isRead ? FontWeight.normal : FontWeight.w600
                                    )
                                  ),
                                ],
                              ),
                              if (body.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  body, 
                                  style: TextStyle(
                                    color: isRead ? Colors.grey[600] : Colors.black54, 
                                    fontSize: 14, 
                                    height: 1.4
                                  ), 
                                  maxLines: 2, 
                                  overflow: TextOverflow.ellipsis
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- COMPONENTES VISUALES ---

  // Formato de fecha inteligente (ej: "14:30", "Ayer", "24 Mar")
  String _formatTime(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final diff = now.difference(date);
    final locale = Localizations.localeOf(context).toString();

    if (diff.inDays == 0 && now.day == date.day) {
      return DateFormat.Hm(locale).format(date); // Solo hora
    } else if (diff.inDays < 2) {
      return "Ayer"; // Podrías traducirlo con l10n si quieres perfección
    } else {
      return DateFormat.MMMd(locale).format(date); // Ej: 24 Mar
    }
  }

  Widget _buildTypeIndicator(String type, bool isRead) {
    // Si ya se leyó, mostramos un punto gris sutil. Si no, el icono de color.
    if (isRead) {
      return Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          shape: BoxShape.circle
        ),
      );
    }

    IconData icon;
    Color color;

    switch (type) {
      case 'chat': 
        icon = Icons.chat_bubble; // Relleno para destacar más
        color = const Color(0xFF29B6F6); 
        break;
      case 'request_join': 
        icon = Icons.person; 
        color = const Color(0xFFFFA726); 
        break;
      case 'request_accepted': 
        icon = Icons.check_circle; 
        color = const Color(0xFF66BB6A); 
        break;
      default: 
        icon = Icons.circle; 
        color = Colors.grey;
    }

    return Icon(icon, size: 18, color: color); // Icono pequeño sin círculo de fondo (Más limpio)
  }

  // --- LÓGICA DE NAVEGACIÓN (Intacta) ---
  Future<void> _handleNotificationTap(
    BuildContext context, 
    DataService dataService, 
    String uid, 
    String notifId, 
    String? activityId, 
    String type,
    String activityTitle
  ) async {
    final l10n = AppLocalizations.of(context)!;
    
    dataService.markNotificationAsRead(uid, notifId);

    if (activityId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.black)), // Loader negro minimalista
    );

    try {
      final doc = await FirebaseFirestore.instance.collection('activities').doc(activityId).get();
      
      if (context.mounted) Navigator.pop(context); 

      if (!doc.exists) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.msgActivityNoLongerExists)));
        }
        return;
      }

      final activity = Activity.fromFirestore(doc);

      if (context.mounted) {
        if (type == 'request_join') {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => ManageRequestsScreen(activityId: activityId, activityTitle: activity.title))
          );
        } 
        else if (type == 'chat') {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => ChatScreen(activity: activity))
          );
        }
        else {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => ActivityDetailScreen(activity: activity))
          );
        }
      }

    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${l10n.msgErrorLoadingActivity}: $e")));
      }
    }
  }
}