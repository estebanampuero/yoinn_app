import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/activity_model.dart';
import '../models/user_model.dart';
import '../services/data_service.dart';
import '../screens/profile_screen.dart'; // <--- IMPORTANTE: Para poder navegar al perfil

class ActivityCard extends StatelessWidget {
  final Activity activity;
  final VoidCallback onTap;

  const ActivityCard({super.key, required this.activity, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, d MMM', 'es_ES').format(activity.dateTime);
    final timeStr = DateFormat('h:mm a').format(activity.dateTime);
    
    // --- LÓGICA FOMO (URGENCIA) ---
    final spotsLeft = activity.maxAttendees - activity.acceptedCount;
    // Consideramos urgente si quedan 3 o menos
    final isUrgent = spotsLeft > 0 && spotsLeft <= 3; 
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
              // --- IMAGEN ---
              Stack(
                children: [
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
                  
                  // BADGE DE CATEGORÍA
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
                        activity.category.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF29B6F6)),
                      ),
                    ),
                  ),

                  // --- BADGE FOMO / URGENCIA (MODIFICADO) ---
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
                            // AQUÍ ESTÁ EL CAMBIO DE LÓGICA SINGULAR/PLURAL
                            Text(
                              spotsLeft == 1 
                                  ? "¡Solo queda 1 cupo!" 
                                  : "¡Solo quedan $spotsLeft cupos!",
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
              
              // --- INFORMACIÓN ---
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

                    const SizedBox(height: 12),

                    // --- FACEPILE (ASISTENTES) ---
                    if (activity.acceptedCount > 0)
                      Row(
                        children: [
                          SizedBox(
                            height: 28,
                            width: 20.0 * activity.participantImages.take(3).length + 10,
                            child: Stack(
                              children: [
                                for (int i = 0; i < activity.participantImages.take(3).length; i++)
                                  Positioned(
                                    left: i * 18.0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: CircleAvatar(
                                        radius: 12,
                                        backgroundImage: NetworkImage(activity.participantImages[i]),
                                        backgroundColor: Colors.grey[300],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "+${activity.acceptedCount} van",
                            style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          if (!isFull)
                            Text(
                              "${activity.acceptedCount}/${activity.maxAttendees} cupos",
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            )
                        ],
                      ),
                  ],
                ),
              ),
              
              // --- HOST (CLICKEABLE) ---
              InkWell(
                onTap: () {
                  // Navegar al perfil del organizador
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(uid: activity.hostUid),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9), // Gris muy suave
                    border: Border(top: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: FutureBuilder<UserModel?>(
                    future: Provider.of<DataService>(context, listen: false).getUserProfile(activity.hostUid),
                    builder: (context, snapshot) {
                      final host = snapshot.data;
                      final hostName = host?.name ?? '...';
                      final hostPic = host?.profilePictureUrl;
                      
                      final isProHost = (host?.activitiesCreatedCount ?? 0) > 5;
                      final isVerified = host?.isVerified ?? false;

                      return Row(
                        children: [
                          // Foto pequeña del host
                          CircleAvatar(
                            radius: 10,
                            backgroundImage: hostPic != null && hostPic.isNotEmpty 
                                ? NetworkImage(hostPic) 
                                : null,
                            backgroundColor: Colors.grey[300],
                            child: hostPic == null || hostPic.isEmpty 
                                ? const Icon(Icons.person, size: 12, color: Colors.white) 
                                : null,
                          ),
                          const SizedBox(width: 8),
                          
                          Text("Organiza:", style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                          const SizedBox(width: 6),
                          
                          Text(
                            hostName,
                            style: TextStyle(
                              fontSize: 12, 
                              fontWeight: FontWeight.bold,
                              color: isProHost ? const Color(0xFF0097A7) : Colors.black87
                            ),
                          ),
                          
                          if (isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, size: 14, color: Colors.blue),
                          ],
                          if (isProHost) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                          ],
                          
                          const Spacer(),
                          // Icono de flecha para indicar que es clickeable
                          const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}