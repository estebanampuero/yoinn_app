import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges; // Asegúrate de tener: flutter pub add badges
import '../services/auth_service.dart';
import '../services/data_service.dart';
import 'feed_screen.dart';
import 'map_screen.dart';
import 'notifications_screen.dart'; // Tu pantalla de lista de notificaciones

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const FeedScreen(),
    const MapScreen(),
    const NotificationsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFF97316).withOpacity(0.2),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt, color: Color(0xFFF97316)),
            label: 'Actividades',
          ),
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: Color(0xFFF97316)),
            label: 'Mapa',
          ),
          // --- AQUÍ ESTÁ LA CAMPANA CON BADGE ---
          NavigationDestination(
            icon: Consumer<DataService>(
              builder: (context, data, child) {
                final uid = Provider.of<AuthService>(context, listen: false).currentUser?.uid;
                
                // Si no hay usuario, mostramos icono sin badge
                if (uid == null) return const Icon(Icons.notifications_outlined);

                return StreamBuilder<int>(
                  // Escucha la cantidad de no leídas
                  stream: data.getUnreadCount(uid),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    
                    return badges.Badge(
                      // Solo mostramos el badge si hay algo nuevo
                      showBadge: count > 0,
                      badgeContent: Text(
                        '$count', 
                        style: const TextStyle(color: Colors.white, fontSize: 10)
                      ),
                      badgeStyle: const badges.BadgeStyle(badgeColor: Colors.red),
                      child: const Icon(Icons.notifications_outlined),
                    );
                  },
                );
              },
            ),
            selectedIcon: const Icon(Icons.notifications, color: Color(0xFFF97316)),
            label: 'Alertas',
          ),
        ],
      ),
    );
  }
}