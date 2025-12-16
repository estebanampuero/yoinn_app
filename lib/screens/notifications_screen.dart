import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // timeago es mejor, pero usaremos intl por simplicidad
import '../services/auth_service.dart';
import '../services/data_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    final dataService = Provider.of<DataService>(context, listen: false);

    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notificaciones"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: dataService.getUserNotifications(user.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          
          if (docs.isEmpty) {
            return const Center(child: Text("No tienes notificaciones", style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final notifId = docs[index].id;
              final bool isRead = data['read'] ?? false;
              final Timestamp? ts = data['timestamp'];
              final timeStr = ts != null ? DateFormat('dd MMM, HH:mm').format(ts.toDate()) : '';

              return Container(
                color: isRead ? Colors.white : const Color(0xFFFFF7ED), // Naranja muy claro si no leída
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isRead ? Colors.grey[200] : const Color(0xFFF97316),
                    child: Icon(
                      data['type'] == 'application' ? Icons.person_add : Icons.chat,
                      color: isRead ? Colors.grey : Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(data['message'] ?? '', style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
                  subtitle: Text(timeStr, style: const TextStyle(fontSize: 12)),
                  onTap: () {
                    // Marcar como leída
                    dataService.markNotificationAsRead(user.uid, notifId);
                    // Aquí podrías navegar al detalle de la actividad relacionada (data['relatedId'])
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}