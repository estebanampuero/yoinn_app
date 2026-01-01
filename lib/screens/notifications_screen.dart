import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 
import 'package:yoinn_app/l10n/app_localizations.dart'; // <--- IMPORTANTE

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
      backgroundColor: const Color(0xFFF0F8FA),
      appBar: AppBar(
        title: Text(l10n.screenNotificationsTitle, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, 
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: dataService.getUserNotifications(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text(l10n.msgErrorLoadingNotifications));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4)));
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_none, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(l10n.msgNoNewNotifications, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (c, i) => const SizedBox(height: 10),
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
              
              // Fecha localizada automáticamente
              final timeStr = timestamp != null 
                  ? DateFormat('d MMM, HH:mm', Localizations.localeOf(context).toString()).format(timestamp.toDate()) 
                  : '';

              return Dismissible(
                key: Key(notifId),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  FirebaseFirestore.instance.collection('users').doc(uid).collection('notifications').doc(notifId).delete();
                },
                child: Card(
                  elevation: 0,
                  color: isRead ? Colors.white : const Color(0xFFE0F7FA), 
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isRead ? BorderSide.none : const BorderSide(color: Color(0xFF00BCD4), width: 0.5)
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: _getIconColor(type).withOpacity(0.1),
                      child: Icon(_getIcon(type), color: _getIconColor(type)),
                    ),
                    title: Text(
                      title, 
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        fontSize: 15
                      )
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (body.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(body, style: TextStyle(color: Colors.grey[700], fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                        const SizedBox(height: 6),
                        Text(timeStr, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                      ],
                    ),
                    onTap: () => _handleNotificationTap(context, dataService, uid, notifId, activityId, type, title),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- ÍCONOS SEGÚN EL TIPO ---
  IconData _getIcon(String type) {
    switch (type) {
      case 'chat': return Icons.chat_bubble_outline;
      case 'request_join': return Icons.person_add_alt_1;
      case 'request_accepted': return Icons.check_circle_outline;
      default: return Icons.notifications_outlined;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'chat': return Colors.blue;
      case 'request_join': return Colors.orange;
      case 'request_accepted': return Colors.green;
      default: return Colors.grey;
    }
  }

  // --- LÓGICA DE NAVEGACIÓN INTELIGENTE ---
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
    
    // 1. Marcar como leída
    dataService.markNotificationAsRead(uid, notifId);

    if (activityId == null) return;

    // 2. Mostrar carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4))),
    );

    try {
      // 3. Buscar la actividad
      final doc = await FirebaseFirestore.instance.collection('activities').doc(activityId).get();
      
      if (context.mounted) Navigator.pop(context); // Cerrar loading

      if (!doc.exists) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.msgActivityNoLongerExists)));
        }
        return;
      }

      final activity = Activity.fromFirestore(doc);

      if (context.mounted) {
        // 4. Navegar según el tipo
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