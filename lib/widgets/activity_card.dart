import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/activity_model.dart';
import '../models/user_model.dart';
import '../services/data_service.dart';

class ActivityCard extends StatelessWidget {
  final Activity activity;
  final VoidCallback onTap;

  const ActivityCard({super.key, required this.activity, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, d MMM', 'es_ES').format(activity.dateTime);
    final timeStr = DateFormat('h:mm a').format(activity.dateTime);
    
    // --- LÓGICA FOMO (URGENCIA) ---
    // Calculamos cuántos lugares quedan reales
    final spotsLeft = activity.maxAttendees - activity.acceptedCount;
    // Es urgente si queda 1 o 2 lugares
    final isUrgent = spotsLeft > 0 && spotsLeft <= 2;
    final isFull = spotsLeft <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00BCD4).withOpacity(0.08), 
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: const Color(0xFF00BCD4).withOpacity(0.1),
          highlightColor: const Color(0xFF00BCD4).withOpacity(0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  // Imagen Principal
                  activity.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: activity.imageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(height: 180, color: const Color(0xFFE0F7FA)),
                          errorWidget: (context, url, error) => Container(height: 180, color: Colors.grey[200], child: const Icon(Icons.broken_image)),
                        )
                      : Image.network('https://via.placeholder.com/400x200', height: 180, width: double.infinity, fit: BoxFit.cover),
                  
                  // BADGE DE CATEGORÍA (Arriba derecha)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Text(
                        activity.category.toUpperCase(), // Puedes usar tu función de traducción aquí si la tienes
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF29B6F6)),
                      ),
                    ),
                  ),

                  // --- BADGE FOMO / URGENCIA (Arriba Izquierda) ---
                  if (isUrgent)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              "¡Solo quedan $spotsLeft!",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (isFull)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text("AGOTADO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ),
                ],
              ),
              
              // Contenido Texto
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF006064)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Color(0xFF26C6DA)),
                        const SizedBox(width: 6),
                        Text("$dateStr • $timeStr", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Color(0xFF26C6DA)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(activity.location, style: TextStyle(color: Colors.grey[600], fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // --- SECCIÓN DEL HOST (Con Gamificación) ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F7FA).withOpacity(0.3),
                  border: Border(top: BorderSide(color: const Color(0xFFE0F7FA))),
                ),
                child: FutureBuilder<UserModel?>(
                  future: Provider.of<DataService>(context, listen: false).getUserProfile(activity.hostUid),
                  builder: (context, snapshot) {
                    final host = snapshot.data;
                    final hostName = host?.name ?? '...';
                    final hostPic = host?.profilePictureUrl;
                    
                    // Lógica de Nivel: Si creó > 5 actividades es "Pro/Guía"
                    final isProHost = (host?.activitiesCreatedCount ?? 0) > 5;
                    final isVerified = host?.isVerified ?? false;

                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: isProHost 
                              ? Border.all(color: Colors.amber, width: 2) // Borde Dorado
                              : null
                          ),
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: const Color(0xFFB2EBF2),
                            backgroundImage: hostPic != null ? NetworkImage(hostPic) : null,
                            child: hostPic == null ? const Icon(Icons.person, size: 12, color: Colors.white) : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hostName,
                          style: TextStyle(
                            fontSize: 12, 
                            color: Colors.grey[700], 
                            fontWeight: isProHost ? FontWeight.bold : FontWeight.w500
                          ),
                        ),
                        // Iconos de estatus
                        if (isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, size: 14, color: Colors.blue),
                        ],
                        if (isProHost) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                        ]
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}