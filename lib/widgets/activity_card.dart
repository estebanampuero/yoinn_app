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

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00BCD4).withOpacity(0.08), // Sombra cian muy sutil
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: const Color(0xFF00BCD4).withOpacity(0.1), // Onda cian
          highlightColor: const Color(0xFF00BCD4).withOpacity(0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  activity.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: activity.imageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 180,
                            color: const Color(0xFFE0F7FA),
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00BCD4))),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 180,
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        )
                      : Image.network(
                          'https://via.placeholder.com/400x200',
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.5,
                          color: Color(0xFF29B6F6), // Azul Brillante para resaltar
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006064), // Cian muy oscuro para texto
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Color(0xFF26C6DA)), // Turquesa
                        const SizedBox(width: 6),
                        Text("$dateStr • $timeStr", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Color(0xFF26C6DA)), // Turquesa
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            activity.location,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F7FA).withOpacity(0.3), // Fondo super suave
                  border: Border(top: BorderSide(color: const Color(0xFFE0F7FA))),
                ),
                child: FutureBuilder<UserModel?>(
                  future: Provider.of<DataService>(context, listen: false).getUserProfile(activity.hostUid),
                  builder: (context, snapshot) {
                    final hostName = snapshot.data?.name ?? 'Cargando...';
                    final hostPic = snapshot.data?.profilePictureUrl;

                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: const Color(0xFFB2EBF2),
                          backgroundImage: hostPic != null ? NetworkImage(hostPic) : null,
                          child: hostPic == null ? const Icon(Icons.person, size: 12, color: Colors.white) : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Organizado por $hostName",
                          style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
                        ),
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