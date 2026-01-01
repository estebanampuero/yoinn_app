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

  // COLORES DE MARCA (Aesthetic Pro)
  final Color _brandColor = const Color(0xFF00BCD4);
  final Color _bgScreenColor = const Color(0xFFF0F8FA);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context, listen: false);
    final dataService = Provider.of<DataService>(context, listen: false);
    final uid = authService.currentUser?.uid;

    if (uid == null) return Center(child: Text(l10n.msgLoginToViewAlerts));

    return Scaffold(
      backgroundColor: _bgScreenColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.screenNotificationsTitle, 
          style: TextStyle(color: _brandColor, fontWeight: FontWeight.w900, fontSize: 26, letterSpacing: -0.5),
        ),
        centerTitle: false,
        automaticallyImplyLeading: false, 
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: dataService.getUserNotifications(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text(l10n.msgErrorLoadingNotifications));
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(strokeWidth: 2, color: _brandColor));
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20)]
                    ),
                    child: Icon(Icons.notifications_none_rounded, size: 60, color: Colors.grey[300]),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.msgNoNewNotifications, 
                    style: TextStyle(color: Colors.grey[400], fontSize: 16, fontWeight: FontWeight.w600)
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5252),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                ),
                onDismissed: (direction) {
                  FirebaseFirestore.instance.collection('users').doc(uid).collection('notifications').doc(notifId).delete();
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: InkWell(
                    onTap: () => _handleNotificationTap(context, dataService, uid, notifId, activityId, type, title),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: isRead ? null : Border.all(color: _brandColor.withOpacity(0.3), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. ICONO ESTILIZADO
                          _buildAestheticIcon(type),
                          
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
                                          fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                          fontSize: 15,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1, 
                                        overflow: TextOverflow.ellipsis
                                      ),
                                    ),
                                    if (!isRead)
                                      Container(
                                        width: 8, height: 8,
                                        margin: const EdgeInsets.only(left: 8),
                                        decoration: BoxDecoration(color: _brandColor, shape: BoxShape.circle),
                                      )
                                  ],
                                ),
                                const SizedBox(height: 6),
                                if (body.isNotEmpty)
                                  Text(
                                    body, 
                                    style: TextStyle(
                                      color: isRead ? Colors.grey[500] : Colors.grey[700], 
                                      fontSize: 14, 
                                      height: 1.4
                                    ), 
                                    maxLines: 2, 
                                    overflow: TextOverflow.ellipsis
                                  ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    timeStr, 
                                    style: TextStyle(
                                      fontSize: 11, 
                                      color: Colors.grey[400],
                                      fontWeight: FontWeight.w500
                                    )
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  String _formatTime(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final diff = now.difference(date);
    final locale = Localizations.localeOf(context).toString();

    if (diff.inDays == 0 && now.day == date.day) {
      return DateFormat.Hm(locale).format(date); 
    } else if (diff.inDays < 2) {
      return "Ayer"; 
    } else {
      return DateFormat.MMMd(locale).format(date); 
    }
  }

  Widget _buildAestheticIcon(String type) {
    IconData icon;
    Color color;
    Color bgColor;

    switch (type) {
      case 'chat': 
        icon = Icons.chat_bubble_rounded; 
        color = const Color(0xFF29B6F6); 
        bgColor = const Color(0xFFE1F5FE);
        break;
      case 'request_join': 
        icon = Icons.person_add_rounded; 
        color = const Color(0xFFFFA726); 
        bgColor = const Color(0xFFFFF3E0);
        break;
      case 'request_accepted': 
        icon = Icons.check_circle_rounded; 
        color = const Color(0xFF66BB6A); 
        bgColor = const Color(0xFFE8F5E9);
        break;
      default: 
        icon = Icons.notifications_rounded; 
        color = Colors.grey;
        bgColor = Colors.grey.shade100;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 22, color: color),
    );
  }

  // --- LÓGICA DE NAVEGACIÓN ---
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

    // Loader minimalista
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)), 
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