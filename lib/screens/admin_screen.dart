import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/activity_model.dart';
import 'activity_detail_screen.dart'; // NECESARIO PARA NAVEGAR

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  final Color _brandColor = const Color(0xFF00BCD4);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --- NAVEGACIÓN A DETALLE (NUEVO) ---
  Future<void> _inspectActivity(String activityId) async {
    // Mostramos un feedback rápido
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Cargando actividad..."), duration: Duration(milliseconds: 500)),
    );

    try {
      // Buscamos el documento fresco en Firebase
      final doc = await FirebaseFirestore.instance.collection('activities').doc(activityId).get();
      
      if (doc.exists && mounted) {
        // Convertimos a objeto Activity
        final activity = Activity.fromFirestore(doc);
        
        // Navegamos al detalle
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ActivityDetailScreen(activity: activity)),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("La actividad no existe (posiblemente ya fue eliminada)."), backgroundColor: Colors.orange),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al cargar: $e")));
      }
    }
  }

  // --- ACCIONES DE ELIMINACIÓN ---
  Future<void> _deleteUser(String userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Eliminar Usuario"),
        content: Text("¿Eliminar a $userName permanentemente?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("ELIMINAR", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Usuario eliminado")));
    }
  }

  Future<void> _deleteActivity(String activityId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Eliminar Actividad"),
        content: Text("¿Borrar '$title'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("ELIMINAR", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('activities').doc(activityId).delete();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Actividad eliminada")));
    }
  }

  // --- ACCIONES DE REPORTES ---
  Future<void> _dismissReport(String reportId) async {
    await FirebaseFirestore.instance.collection('reports').doc(reportId).delete();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reporte descartado")));
  }

  Future<void> _acceptReport(String reportId, String activityId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar Sanción"),
        content: const Text("Esto eliminará la actividad reportada y cerrará el reporte. ¿Proceder?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("BORRAR TODO", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('activities').doc(activityId).delete();
      await FirebaseFirestore.instance.collection('reports').doc(reportId).delete();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Contenido eliminado por moderación")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Buscar...",
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(icon: const Icon(Icons.clear, size: 20, color: Colors.grey), onPressed: () => _searchController.clear())
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: InputBorder.none,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _brandColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _brandColor,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: "Usuarios"),
            Tab(icon: Icon(Icons.event), text: "Actividades"),
            Tab(icon: Icon(Icons.warning_amber_rounded), text: "Reportes"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ---------------------------------------------
          // PESTAÑA 1: USUARIOS
          // ---------------------------------------------
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').orderBy('name').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] ?? '').toString().toLowerCase();
                final email = (data['email'] ?? '').toString().toLowerCase();
                return name.contains(_searchQuery) || email.contains(_searchQuery);
              }).toList();

              if (docs.isEmpty) return const Center(child: Text("No se encontraron usuarios."));

              return ListView.separated(
                padding: const EdgeInsets.all(10),
                itemCount: docs.length,
                separatorBuilder: (c, i) => const Divider(),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: (data['profilePictureUrl'] ?? '').isNotEmpty ? NetworkImage(data['profilePictureUrl']) : null,
                      child: (data['profilePictureUrl'] ?? '').isEmpty ? const Icon(Icons.person) : null,
                    ),
                    title: Text(data['name'] ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(data['email'] ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      onPressed: () => _deleteUser(docs[index].id, data['name'] ?? ''),
                    ),
                  );
                },
              );
            },
          ),

          // ---------------------------------------------
          // PESTAÑA 2: ACTIVIDADES
          // ---------------------------------------------
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('activities').orderBy('dateTime', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs.where((doc) {
                final activity = Activity.fromFirestore(doc);
                return activity.title.toLowerCase().contains(_searchQuery) || activity.category.toLowerCase().contains(_searchQuery);
              }).toList();

              if (docs.isEmpty) return const Center(child: Text("No se encontraron actividades."));

              return ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final activity = Activity.fromFirestore(docs[index]);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: activity.imageUrl.isNotEmpty
                          ? Image.network(activity.imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                          : const Icon(Icons.event),
                      title: Text(activity.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(activity.category),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        onPressed: () => _deleteActivity(activity.id, activity.title),
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // ---------------------------------------------
          // PESTAÑA 3: REPORTES
          // ---------------------------------------------
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('reports').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              
              final reports = snapshot.data!.docs;

              if (reports.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 60, color: Colors.green),
                      SizedBox(height: 10),
                      Text("¡Sin reportes pendientes!"),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final reportData = reports[index].data() as Map<String, dynamic>;
                  final reportId = reports[index].id;
                  final activityId = reportData['activityId'] ?? '';
                  final reason = reportData['reason'] ?? 'Sin razón';
                  final date = (reportData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

                  return Card(
                    color: Colors.red[50],
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    clipBehavior: Clip.antiAlias,
                    child: InkWell( // <--- AHORA ES CLICKEABLE
                      onTap: () => _inspectActivity(activityId),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning, color: Colors.red),
                                const SizedBox(width: 8),
                                const Text("ACTIVIDAD REPORTADA", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                const Spacer(),
                                Text(DateFormat('dd/MM HH:mm').format(date), style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text("Motivo: $reason", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text("ID Actividad: $activityId", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            
                            const SizedBox(height: 8),
                            const Row(
                              children: [
                                Icon(Icons.touch_app, size: 14, color: Colors.blue),
                                SizedBox(width: 4),
                                Text("Toca para revisar detalles", style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),

                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () => _dismissReport(reportId),
                                  style: OutlinedButton.styleFrom(backgroundColor: Colors.white),
                                  child: const Text("Descartar (Falso)"),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () => _acceptReport(reportId, activityId),
                                  icon: const Icon(Icons.delete, color: Colors.white, size: 16),
                                  label: const Text("Borrar Actividad", style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}