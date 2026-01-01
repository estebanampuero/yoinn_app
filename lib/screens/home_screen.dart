import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges; 
import 'package:yoinn_app/l10n/app_localizations.dart'; 

import '../services/auth_service.dart';
import '../services/data_service.dart';
import 'feed_screen.dart';
import 'map_screen.dart';
import 'notifications_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // COLOR DE MARCA (Cyan Aesthetic)
  final Color _brandColor = const Color(0xFF00BCD4);

  final List<Widget> _screens = [
    const FeedScreen(),
    const MapScreen(),
    const NotificationsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; 

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          // Tipografía dinámica: Bold y color marca al seleccionar
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _brandColor);
            }
            return TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade600);
          }),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          height: 70, // Altura ligeramente más estilizada
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent, // Evita el tinte automático de Material 3
          indicatorColor: _brandColor.withOpacity(0.12), // Fondo de selección suave (Pill)
          elevation: 5,
          shadowColor: Colors.black.withOpacity(0.1),
          destinations: [
            // 1. ACTIVIDADES (FEED)
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined, color: Colors.grey), // Icono más moderno para Feed
              selectedIcon: Icon(Icons.dashboard_rounded, color: _brandColor),
              label: l10n.navActivities,
            ),
            
            // 2. MAPA
            NavigationDestination(
              icon: const Icon(Icons.map_outlined, color: Colors.grey),
              selectedIcon: Icon(Icons.map_rounded, color: _brandColor),
              label: l10n.navMap,
            ),
            
            // 3. ALERTAS (Con Badge inteligente en ambos estados)
            NavigationDestination(
              icon: _buildNotificationIcon(context, isSelected: false),
              selectedIcon: _buildNotificationIcon(context, isSelected: true),
              label: l10n.navAlerts,
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para mantener la lógica del Badge limpia y consistente
  Widget _buildNotificationIcon(BuildContext context, {required bool isSelected}) {
    return Consumer<DataService>(
      builder: (context, data, child) {
        final uid = Provider.of<AuthService>(context, listen: false).currentUser?.uid;
        
        // Icono base dependiendo del estado
        final baseIcon = Icon(
          isSelected ? Icons.notifications_rounded : Icons.notifications_outlined,
          color: isSelected ? _brandColor : Colors.grey,
        );

        if (uid == null) return baseIcon;

        return StreamBuilder<int>(
          stream: data.getUnreadCount(uid),
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            
            return badges.Badge(
              showBadge: count > 0,
              badgeContent: Text(
                '$count', 
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
              ),
              badgeStyle: badges.BadgeStyle(
                badgeColor: const Color(0xFFFF5252), // Rojo suave aesthetic
                padding: const EdgeInsets.all(5),
                elevation: 0,
              ),
              child: baseIcon,
            );
          },
        );
      },
    );
  }
}