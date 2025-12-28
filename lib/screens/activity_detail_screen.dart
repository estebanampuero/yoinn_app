import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart'; 
import 'package:firebase_analytics/firebase_analytics.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:intl/intl.dart'; 

import '../models/activity_model.dart';
import '../services/data_service.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart'; 

import 'edit_activity_screen.dart';
// --- IMPORTS RESTAURADOS PARA NAVEGACIÓN ---
import 'chat_screen.dart'; 
import 'manage_requests_screen.dart';

import '../widgets/activity_detail_components.dart'; 
import '../widgets/activity_limit_paywall.dart';

class ActivityDetailScreen extends StatefulWidget {
  final Activity activity;
  const ActivityDetailScreen({super.key, required this.activity});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  bool _isJoining = false;

  // --- LÓGICA DE APUESTA (BETTING) ---
  void _confirmAndJoin() async {
    final dataService = Provider.of<DataService>(context, listen: false);
    final user = Provider.of<AuthService>(context, listen: false).currentUser;

    if (user == null) return;

    // 1. Verificar tickets restantes
    int remaining = await dataService.getRemainingFreeJoins(user.uid);
    
    // Si es -1 (PRO), pasa directo
    if (remaining == -1) {
      _joinActivity();
      return;
    }

    // Si tiene 0, mostramos paywall directo (sin preguntar)
    if (remaining == 0) {
      if (mounted) _showPaywall(context);
      return;
    }

    // 2. DIALOGO DE APUESTA (PSICOLOGÍA)
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("¿Usar 1 Ticket?"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Estás a punto de usar 1 de tus tickets semanales para postular a esta actividad."),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.confirmation_number, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text("Te quedarán: ${remaining - 1} tickets", style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316)),
              onPressed: () {
                Navigator.pop(ctx); 
                _joinActivity(); 
              },
              child: const Text("USAR TICKET", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  void _joinActivity() async {
    setState(() => _isJoining = true);
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final dataService = Provider.of<DataService>(context, listen: false);
    final user = authService.currentUser;

    bool isPremium = user?.isPremium ?? false;
    if (!isPremium) {
      isPremium = await SubscriptionService.isUserPremium();
    }
    
    await FirebaseAnalytics.instance.logEvent(
       name: 'join_activity_request',
       parameters: {
          'category': widget.activity.category,
          'is_premium': isPremium.toString(),
          'activity_id': widget.activity.id,
       },
    );

    if (user != null) {
      try {
        final userModel = await dataService.getUserProfile(user.uid);
        if (userModel != null) {
          await dataService.applyToActivity(widget.activity.id, userModel);
          await FirebaseAnalytics.instance.logEvent(name: 'join_activity_success');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("¡Solicitud enviada! Ticket usado.")),
            );
          }
        }
      } catch (e) {
        if (e.toString().contains("Ticket") || e.toString().contains("Límite") || e.toString().contains("Limit")) {
          if (mounted) {
            await FirebaseAnalytics.instance.logEvent(name: 'paywall_shown', parameters: {'source': 'activity_limit'});
            _showPaywall(context);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error: ${e.toString().replaceAll('Exception:', '')}")),
            );
          }
        }
      }
    }
    
    if (mounted) setState(() => _isJoining = false);
  }

  void _showPaywall(BuildContext context) async {
    final package = await SubscriptionService.getCurrentOffering();
    if (package != null && mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => ActivityLimitPaywall(package: package),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hazte PRO para unirte a más actividades.")));
      }
    }
  }

  void _mostrarConfirmacionEliminar() {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text("Eliminar Actividad"),
          content: const Text("¿Estás seguro? Esta acción no se puede deshacer."),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancelar")),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); 
                _eliminarActividad(); 
              },
              child: const Text("Eliminar", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _eliminarActividad() async {
    try {
      await Provider.of<DataService>(context, listen: false).deleteActivity(widget.activity.id); 
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Actividad eliminada")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _compartirActividad() {
    final String deepLink = 'https://yoinn.app/activity/${widget.activity.id}';
    final dateFormatted = DateFormat('EEEE d, h:mm a', 'es_ES').format(widget.activity.dateTime);
    final String mensaje = '''
¡Hey! 🌟 Encontré esta actividad en Yoinn y pensé que te gustaría:

"${widget.activity.title}"
📅 $dateFormatted
📍 ${widget.activity.location}

👇 Toca aquí para ver detalles o descargar la app:
$deepLink
''';
    Share.share(mensaje);
    FirebaseAnalytics.instance.logEvent(name: 'share_activity', parameters: {'activity_id': widget.activity.id});
  }

  void _showOptions(bool isHost) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blue),
              title: const Text("Compartir Actividad"),
              onTap: () { Navigator.pop(ctx); _compartirActividad(); },
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
                title: const Text("Eliminar", style: TextStyle(color: Colors.red)),
                onTap: () { Navigator.pop(ctx); _mostrarConfirmacionEliminar(); },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.flag, color: Colors.orange),
                title: const Text("Reportar"),
                onTap: () { Navigator.pop(ctx); _showReportDialog(); },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.grey),
                title: const Text("Bloquear Usuario"),
                onTap: () { Navigator.pop(ctx); _showBlockDialog(); },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reportar Actividad"),
        content: const Text("¿Por qué quieres reportar esto?"),
        actions: [
          TextButton(
            child: const Text("Es Spam"),
            onPressed: () => _submitReport(ctx, "Spam"),
          ),
          TextButton(
            child: const Text("Contenido Ofensivo"),
            onPressed: () => _submitReport(ctx, "Ofensivo/Inapropiado"),
          ),
          TextButton(child: const Text("Cancelar"), onPressed: () => Navigator.pop(ctx)),
        ],
      ),
    );
  }

  Future<void> _submitReport(BuildContext ctx, String reason) async {
    Navigator.pop(ctx); 
    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'activityId': widget.activity.id, 
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'reportedBy': Provider.of<AuthService>(context, listen: false).currentUser?.uid ?? 'anon',
        'type': 'activity_report'
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gracias. Revisaremos este contenido en menos de 24h."), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al enviar reporte.")));
    }
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Bloquear Usuario"),
        content: const Text("No verás más contenido de este usuario. ¿Continuar?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Usuario bloqueado.")));
            },
            child: const Text("BLOQUEAR", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    final isHost = user?.uid == widget.activity.hostUid;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          ActivitySliverAppBar(
            activity: widget.activity, 
            isHost: isHost,
            onShare: _compartirActividad,
            onOptions: () => _showOptions(isHost),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFE0F7FA), borderRadius: BorderRadius.circular(20)),
                    child: Text(widget.activity.category.toUpperCase(), style: const TextStyle(color: Color(0xFF006064), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(height: 12),
                  Text(widget.activity.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF006064))),
                  
                  const SizedBox(height: 20),
                  HostInfoTile(hostUid: widget.activity.hostUid),
                  
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),

                  ActivityInfoRow(activity: widget.activity),

                  const SizedBox(height: 24),
                  const Text("Sobre la actividad", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(widget.activity.description, style: TextStyle(fontSize: 16, color: Colors.grey[800], height: 1.5)),

                  const SizedBox(height: 24),
                  const Text("Asistentes Confirmados", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  
                  ParticipantsSection(activityId: widget.activity.id),
                  
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
          child: StreamBuilder<QuerySnapshot>(
            stream: Provider.of<DataService>(context, listen: false).getActivityApplications(widget.activity.id),
            builder: (context, snapshot) {
              String? status;
              if (snapshot.hasData && user != null) {
                try {
                  final myDoc = snapshot.data!.docs.firstWhere((doc) => doc['applicantUid'] == user.uid);
                  status = myDoc['status'];
                } catch (_) {}
              }

              // --- 1. VISTA ANFITRIÓN ---
              if (isHost) {
                 return Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     SizedBox(
                       width: double.infinity, height: 45,
                       child: ElevatedButton(
                         style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.white,
                           side: const BorderSide(color: Color(0xFF00BCD4), width: 2),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                         ),
                         onPressed: () {
                           Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(activity: widget.activity)));
                         },
                         child: const Text("Ir al Chat del Grupo", style: TextStyle(fontSize: 16, color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                       ),
                     ),
                     const SizedBox(height: 12),
                     SizedBox(
                       width: double.infinity, height: 45,
                       child: ElevatedButton.icon(
                         style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BCD4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                         onPressed: () {
                           Navigator.push(context, MaterialPageRoute(builder: (_) => ManageRequestsScreen(activityId: widget.activity.id, activityTitle: widget.activity.title)));
                         },
                         icon: const Icon(Icons.people, color: Colors.white),
                         label: const Text("Gestionar Solicitudes", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                       ),
                     ),
                   ],
                 );
              }

              // --- 2. VISTA ACEPTADO ---
              if (status == 'accepted') {
                return SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () {
                       Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(activity: widget.activity)));
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text("¡Estás dentro! Ir al Chat", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                );
              }

              // --- 3. VISTA PENDIENTE ---
              if (status == 'pending') {
                 return SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: null,
                    child: const Text("Solicitud enviada...", style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                );
              }

              // --- 4. VISTA NUEVO USUARIO ---
              final spotsLeft = widget.activity.maxAttendees - widget.activity.acceptedCount;
              final isFull = spotsLeft <= 0;

              return SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFull ? Colors.grey : const Color(0xFF00BCD4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isFull ? null : (_isJoining ? null : _confirmAndJoin),
                  child: _isJoining
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isFull ? "AGOTADO" : "Solicitar Unirme", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}