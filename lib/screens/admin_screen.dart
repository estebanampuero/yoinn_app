import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/data_service.dart';
import 'activity_detail_screen.dart'; // Para ver la actividad reportada
import '../models/activity_model.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel de Administración"),
        backgroundColor: Colors.redAccent, // Color distintivo
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: dataService.getAdminReportsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                  SizedBox(height: 20),
                  Text("¡Todo limpio! No hay reportes pendientes.", style: TextStyle(fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final reportDoc = snapshot.data!.docs[index];
              final reportData = reportDoc.data() as Map<String, dynamic>;
              final reportId = reportDoc.id;
              
              final reason = reportData['reason'] ?? 'Sin razón';
              final type = reportData['type'] ?? 'unknown'; // 'activity' o 'user'
              final reportedId = reportData['reportedId'];
              final date = (reportData['timestamp'] as Timestamp).toDate();

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red[700]),
                          const SizedBox(width: 8),
                          Text("Reporte de ${type.toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          const Spacer(),
                          Text(DateFormat('dd/MM HH:mm').format(date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      const Divider(),
                      Text("Motivo: $reason", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 10),
                      Text("ID Reportado: $reportedId", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Botón Descartar
                          TextButton(
                            onPressed: () => dataService.adminDismissReport(reportId),
                            child: const Text("Descartar (Falso)"),
                          ),
                          const SizedBox(width: 8),
                          
                          // Botón Acción Drástica
                          if (type == 'activity')
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              icon: const Icon(Icons.delete, color: Colors.white),
                              label: const Text("Borrar Actividad", style: TextStyle(color: Colors.white)),
                              onPressed: () {
                                _confirmDialog(context, "Borrar Actividad", "¿Seguro? Esto no se puede deshacer.", () {
                                  dataService.adminDeleteActivity(reportedId, reportId);
                                });
                              },
                            ),
                            
                          if (type == 'user')
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                              icon: const Icon(Icons.block, color: Colors.white),
                              label: const Text("Banear Usuario", style: TextStyle(color: Colors.white)),
                              onPressed: () {
                                _confirmDialog(context, "Banear Usuario", "El usuario no podrá entrar más.", () {
                                  dataService.adminBanUser(reportedId, reportId);
                                });
                              },
                            ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDialog(BuildContext context, String title, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(ctx);
            },
            child: const Text("CONFIRMAR", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}