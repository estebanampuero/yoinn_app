import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoinn_app/l10n/app_localizations.dart'; // <--- IMPORTANTE

import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../services/subscription_service.dart'; 
import '../models/user_model.dart'; 
import '../widgets/activity_card.dart';
import 'activity_detail_screen.dart';
import 'create_activity_screen.dart';
import 'profile_screen.dart';
import 'paywall_pro_screen.dart'; 

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  bool _isPremium = false; 

  // Las claves se mantienen para lógica interna, la traducción es visual
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

  Future<void> _checkPremiumStatus() async {
    final revenueCatStatus = await SubscriptionService.isUserPremium();
    
    bool manualStatus = false;
    if (mounted) { 
      final authService = Provider.of<AuthService>(context, listen: false);
      final dataService = Provider.of<DataService>(context, listen: false);
      
      if (authService.currentUser != null) {
        final user = await dataService.getUserProfile(authService.currentUser!.uid);
        manualStatus = user?.isManualPro ?? false;
      }
    }

    if (mounted) {
      setState(() {
        _isPremium = revenueCatStatus || manualStatus;
      });
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

  // Helper para traducir la categoría visualmente
  String _getCategoryName(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    if (key == 'Todas') return l10n.catAll;
    if (key == 'Deporte') return l10n.catSport;
    if (key == 'Comida') return l10n.catFood;
    if (key == 'Arte') return l10n.catArt;
    if (key == 'Fiesta') return l10n.catParty;
    if (key == 'Viaje') return l10n.catOutdoor; // O Travel
    if (key == 'Musica') return l10n.hobbyMusic;
    if (key == 'Tecnología') return l10n.hobbyTech;
    if (key == 'Bienestar') return l10n.hobbyWellness;
    return l10n.catOther;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context, listen: false);
    final dataService = Provider.of<DataService>(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          l10n.appTitle, // "Yoinn"
          style: const TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.w800, fontSize: 24),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                 final myUid = authService.currentUser?.uid;
                 if (myUid != null) {
                   Navigator.push(
                     context,
                     MaterialPageRoute(builder: (context) => ProfileScreen(uid: myUid)),
                   ).then((_) => _checkPremiumStatus());
                 }
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3.0), 
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _isPremium 
                          ? const LinearGradient(
                              colors: [
                                Color(0xFFB8860B), 
                                Color(0xFFFFD700), 
                                Color(0xFFD4AF37), 
                                Color(0xFFFFD700), 
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              stops: [0.0, 0.4, 0.7, 1.0]
                            )
                          : null,
                      color: _isPremium ? null : Colors.transparent, 
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage(authService.currentUser?.profilePictureUrl ?? ''),
                      backgroundColor: const Color(0xFFB2EBF2),
                      child: authService.currentUser?.profilePictureUrl == null || authService.currentUser!.profilePictureUrl.isEmpty
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                  ),
                  
                  if (_isPremium)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified, color: Color(0xFFD4AF37), size: 14),
                      ),
                    )
                ],
              ),
            ),
          ),
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
                          hintText: l10n.searchPlaceholder,
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
                
                // Categorías horizontales traducidas
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filterCategories.length,
                    separatorBuilder: (c, i) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final categoryKey = _filterCategories[index];
                      final isSelected = dataService.selectedCategory == categoryKey;
                      
                      return GestureDetector(
                        onTap: () {
                          dataService.setCategoryFilter(categoryKey);
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
                            _getCategoryName(context, categoryKey),
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
                            l10n.msgNoActivitiesTitle, // "No se encontraron actividades"
                            style: TextStyle(fontSize: 18, color: Colors.grey[500], fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(l10n.msgNoActivitiesBody), // "Intenta cambiar los filtros..."
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