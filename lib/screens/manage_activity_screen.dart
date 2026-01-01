import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yoinn_app/l10n/app_localizations.dart'; // <--- IMPORTANTE
import '../models/activity_model.dart';
import '../services/data_service.dart';

class ManageActivityScreen extends StatelessWidget {
  final Activity activity;

  const ManageActivityScreen({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dataService = Provider.of<DataService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.screenManageParticipantsTitle), // "Gestionar Participantes"
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: dataService.getActivityApplications(activity.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(l10n.errorGeneric));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          // Separamos las solicitudes
          final pending = docs.where((doc) => doc['status'] == 'pending').toList();
          final accepted = docs.where((doc) => doc['status'] == 'accepted').toList();

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 60, color: Colors.grey),
                  const SizedBox(height: 10),
                  Text(l10n.msgNoRequestsYet, style: const TextStyle(color: Colors.grey, fontSize: 16)), // "Aún no hay solicitudes"
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pending.isNotEmpty) ...[
                Text(l10n.lblPendingRequests, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), // "Solicitudes Pendientes"
                const SizedBox(height: 10),
                ...pending.map((doc) => _buildUserTile(context, doc, true)),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),
              ],

              if (accepted.isNotEmpty) ...[
                Text(l10n.lblAcceptedParticipants, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)), // "Participantes Aceptados"
                const SizedBox(height: 10),
                ...accepted.map((doc) => _buildUserTile(context, doc, false)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserTile(BuildContext context, DocumentSnapshot doc, bool isPending) {
    final l10n = AppLocalizations.of(context)!;
    final data = doc.data() as Map<String, dynamic>;
    final applicationId = doc.id;
    final name = data['applicantName'] ?? 'Desconocido';
    final pic = data['applicantProfilePictureUrl'] ?? '';
    final dataService = Provider.of<DataService>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: pic.isNotEmpty ? NetworkImage(pic) : null,
              child: pic.isEmpty ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  if (isPending)
                    Text(l10n.lblWantsToJoin, style: const TextStyle(color: Colors.grey, fontSize: 12)) // "Quiere unirse"
                  else
                    Text(l10n.lblConfirmed, style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)), // "Confirmado"
                ],
              ),
            ),
            
            // Botones de acción
            if (isPending)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                       dataService.rejectApplicant(applicationId);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () {
                       dataService.acceptApplicant(applicationId, activity.id, pic);
                    },
                  ),
                ],
              )
            else 
              IconButton(
                icon: const Icon(Icons.person_remove, color: Colors.red),
                tooltip: l10n.tooltipRemoveParticipant, // "Eliminar participante"
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l10n.dialogRemoveParticipantTitle), // "¿Eliminar participante?"
                      content: Text(l10n.dialogRemoveParticipantBody(name)), // "¿Estás seguro de que quieres sacar a {name}..."
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(l10n.btnCancel),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx); 
                            dataService.removeParticipant(applicationId, activity.id, pic);
                          },
                          child: Text(l10n.btnDelete, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}