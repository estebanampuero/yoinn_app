import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../services/subscription_service.dart'; // Importante para verificar premium
import '../models/user_model.dart'; // <--- AGREGADO PARA LEER isManualPro
import '../widgets/activity_card.dart';
import 'activity_detail_screen.dart';
import 'create_activity_screen.dart';
import 'profile_screen.dart';
import 'paywall_pro_screen.dart'; // Nueva pantalla de ventas

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // Estado para controlar la UI según suscripción (RevenueCat O Manual)
  bool _isPremium = false; 

  final List<String> _filterCategories = [
    'Todas', 'Deporte', 'Comida', 'Arte', 'Fiesta', 'Viaje', 'Musica', 'Tecnología', 'Bienestar', 'Otros'
  ];

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Verificamos el estado premium al cargar el feed
  Future<void> _checkPremiumStatus() async {
    // 1. Verificamos suscripción de pago (RevenueCat)
    final revenueCatStatus = await SubscriptionService.isUserPremium();
    
    // 2. Verificamos suscripción manual en Firebase
    bool manualStatus = false;
    if (mounted) { // Check mounted antes de usar context
      final authService = Provider.of<AuthService>(context, listen: false);
      final dataService = Provider.of<DataService>(context, listen: false);
      
      if (authService.currentUser != null) {
        // Obtenemos el perfil para ver si tiene isManualPro
        final user = await dataService.getUserProfile(authService.currentUser!.uid);
        manualStatus = user?.isManualPro ?? false;
      }
    }

    if (mounted) {
      setState(() {
        // Es Premium si pagó O si se lo activamos manualmente
        _isPremium = revenueCatStatus || manualStatus;
      });
    }
  }

  // Abre la pantalla de ventas
  void _openPaywall() async {
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => const PaywallProScreen())
    );
    if (result == true) {
      // Si compró, actualizamos la UI del Feed (borde dorado)
      _checkPremiumStatus();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Ya eres PRO!")));
    }
  }

  Future<void> _pickDateFilter(BuildContext context, DataService dataService) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2026),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00BCD4), 
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      dataService.setDateFilter(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final dataService = Provider.of<DataService>(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Yoinn",
          style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.w800, fontSize: 24),
        ),
        actions: [
          Row(
            children: [
              // --- INTEGRACIÓN: Botón "Pásate a PRO" si NO es premium ---
              if (!_isPremium)
                GestureDetector(
                  onTap: _openPaywall,
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA000)]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 4)],
                    ),
                    child: const Row(
                      children: [
                         Icon(Icons.workspace_premium, color: Colors.white, size: 16),
                         SizedBox(width: 4),
                         Text(
                           "PRO",
                           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                         ),
                      ],
                    ),
                  ),
                ),

              // --- INTEGRACIÓN: Foto de Perfil con lógica Premium ---
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: GestureDetector(
                  onTap: () {
                     final myUid = authService.currentUser?.uid;
                     if (myUid != null) {
                       Navigator.push(
                         context,
                         MaterialPageRoute(builder: (context) => ProfileScreen(uid: myUid)),
                       ).then((_) => _checkPremiumStatus()); // Actualizar al volver del perfil
                     }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2), // Espacio para el borde
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Si es Premium: Borde Dorado. Si no: Transparente (o color normal)
                      border: _isPremium 
                          ? Border.all(color: const Color(0xFFFFD700), width: 2.5) 
                          : null, 
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage(authService.currentUser?.profilePictureUrl ?? ''),
                      backgroundColor: const Color(0xFFB2EBF2),
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          dataService.setSearchQuery(value);
                        },
                        decoration: InputDecoration(
                          hintText: "Buscar...",
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                          filled: true,
                          fillColor: const Color(0xFFE0F7FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5),
                          ),
                        ),
                        cursorColor: const Color(0xFF00BCD4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    GestureDetector(
                      onTap: () => _pickDateFilter(context, dataService),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: dataService.currentFilterDate != null 
                              ? const Color(0xFF29B6F6) 
                              : const Color(0xFFE0F7FA),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.calendar_today, 
                          size: 20, 
                          color: dataService.currentFilterDate != null ? Colors.white : const Color(0xFF006064)
                        ),
                      ),
                    ),
                    if (dataService.currentFilterDate != null) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => dataService.setDateFilter(null),
                        child: const Icon(Icons.close, size: 20, color: Colors.grey),
                      )
                    ]
                  ],
                ),
                const SizedBox(height: 12),
                
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filterCategories.length,
                    separatorBuilder: (c, i) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = _filterCategories[index];
                      final isSelected = dataService.selectedCategory == category;
                      
                      return GestureDetector(
                        onTap: () {
                          dataService.setCategoryFilter(category);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF00BCD4) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF00BCD4) : const Color(0xFFB2EBF2)
                            ),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF00838F),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: dataService.isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4)))
              : dataService.activities.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            "No se encontraron actividades",
                            style: TextStyle(fontSize: 18, color: Colors.grey[500], fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text("Intenta cambiar los filtros o crea una nueva"),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: dataService.refresh,
                    color: const Color(0xFF00BCD4),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: dataService.activities.length,
                      itemBuilder: (context, index) {
                        final activity = dataService.activities[index];
                        return ActivityCard(
                          activity: activity,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ActivityDetailScreen(activity: activity),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'create_activity_btn',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateActivityScreen()),
          );
        },
        backgroundColor: const Color(0xFF00BCD4),
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
    );
  }
}