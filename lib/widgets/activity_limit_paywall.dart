import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';

class ActivityLimitPaywall extends StatelessWidget {
  final Package package;
  const ActivityLimitPaywall({super.key, required this.package});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: 550, 
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          
          const Icon(Icons.auto_awesome, size: 50, color: Color(0xFF00BCD4)),
          const SizedBox(height: 10),
          const Text("Límite Semanal Alcanzado", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          const Text(
            "Has alcanzado tus 3 uniones gratuitas de la semana. Hazte PRO para unirte a todo lo que quieras.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          
          const SizedBox(height: 30),
          
          _buildBenefit(Icons.check_circle, "Uniones Ilimitadas a eventos"),
          _buildBenefit(Icons.public, "Crear eventos en cualquier país"),
          _buildBenefit(Icons.radar, "Radio de búsqueda de hasta 150km"),
          
          const Spacer(),
          
          Text(
            "${package.storeProduct.priceString} / mes", 
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const Text("Cancela cuando quieras", style: TextStyle(color: Colors.grey, fontSize: 12)),
          
          const SizedBox(height: 20),
          
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 5,
              ),
              onPressed: () async {
                final success = await SubscriptionService.purchasePackage(package);
                if (success) {
                  final user = Provider.of<AuthService>(context, listen: false).currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                      'isPremium': true
                    });
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Bienvenido a Yoinn Pro! 🚀")));
                  }
                }
              },
              child: const Text("DESBLOQUEAR AHORA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00BCD4), size: 24),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}