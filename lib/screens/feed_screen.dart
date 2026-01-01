import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoinn_app/l10n/app_localizations.dart'; 

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

  // COLORES DE MARCA
  final Color _brandColor = const Color(0xFF00BCD4);
  final Color _bgScreenColor = const Color(0xFFF0F8FA);
  final Color _textDark = const Color(0xFF2D3142);

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
    // 1. Detectar idioma
    if (mounted) {
       final String langCode = Localizations.localeOf(context).languageCode;
       final authService = Provider.of<AuthService>(context, listen: false);
       final dataService = Provider.of<DataService>(context, listen: false);

       if (authService.currentUser != null) {
         dataService.updateUserLanguage(authService.currentUser!.uid, langCode);
       }
    }

    // 2. Verificar Premium
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
      firstDate: DateTime(2020), 
      lastDate: DateTime(2030),  
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _brandColor, 
              onPrimary: Colors.white,
              onSurface: _textDark,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      dataService.setDateFilter(picked);
    }
  }

  String _getCategoryName(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    if (key == 'Todas') return l10n.catAll;
    if (key == 'Deporte') return l10n.catSport;
    if (key == 'Comida') return l10n.catFood;
    if (key == 'Arte') return l10n.catArt;
    if (key == 'Fiesta') return l10n.catParty;
    if (key == 'Viaje') return l10n.catOutdoor; 
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
      backgroundColor: _bgScreenColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          l10n.appTitle, 
          style: TextStyle(color: _brandColor, fontWeight: FontWeight.w900, fontSize: 26, letterSpacing: -0.5),
        ),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- 1. BADGE PRO (LADO IZQUIERDO, DISEÑO AESTHETIC) ---
              if (_isPremium) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A), // Negro suave (Matte Black)
                    borderRadius: BorderRadius.circular(20), // Píldora completa
                    border: Border.all(color: const Color(0xFFFFD700), width: 1.2), // Dorado fino
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15), 
                        blurRadius: 6, 
                        offset: const Offset(0, 3)
                      )
                    ],
                  ),
                  child: const Text(
                    "PRO",
                    style: TextStyle(
                      color: Color(0xFFFFD700), 
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 12), // Separación limpia entre Badge y Foto
              ],

              // --- 2. AVATAR DE USUARIO ---
              Padding(
                padding: const EdgeInsets.only(right: 20.0),
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
                  child: Container(
                    padding: const EdgeInsets.all(2.5), 
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Anillo dorado sutil si es premium para combinar
                      border: _isPremium ? Border.all(color: const Color(0xFFFFD700).withOpacity(0.8), width: 1.5) : null,
                      boxShadow: _isPremium ? [
                         BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.2), blurRadius: 8)
                      ] : null,
                    ),
                    child: CircleAvatar(
                      radius: 19, 
                      backgroundColor: const Color(0xFFE0F7FA),
                      backgroundImage: NetworkImage(authService.currentUser?.profilePictureUrl ?? ''),
                      child: authService.currentUser?.profilePictureUrl == null || authService.currentUser!.profilePictureUrl.isEmpty
                          ? Icon(Icons.person, color: _brandColor)
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // --- HEADER DE BÚSQUEDA ---
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))
              ]
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: _bgScreenColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => dataService.setSearchQuery(value),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: l10n.searchPlaceholder,
                            hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.normal),
                            prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          ),
                          cursorColor: _brandColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _pickDateFilter(context, dataService),
                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: dataService.currentFilterDate != null ? _brandColor : _bgScreenColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.calendar_month_rounded,
                          color: dataService.currentFilterDate != null ? Colors.white : Colors.grey[600],
                          size: 22,
                        ),
                      ),
                    ),
                    if (dataService.currentFilterDate != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => dataService.setDateFilter(null),
                        child: Container(
                          height: 50,
                          width: 30,
                          alignment: Alignment.center,
                          child: Icon(Icons.close, size: 20, color: Colors.grey[400]),
                        ),
                      )
                    ]
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filterCategories.length,
                    separatorBuilder: (c, i) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final categoryKey = _filterCategories[index];
                      final isSelected = dataService.selectedCategory == categoryKey;
                      return GestureDetector(
                        onTap: () => dataService.setCategoryFilter(categoryKey),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? _brandColor : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? _brandColor : Colors.grey.shade300,
                              width: 1.5
                            ),
                          ),
                          child: Text(
                            _getCategoryName(context, categoryKey),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[600],
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
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
          
          // --- FEED ---
          Expanded(
            child: dataService.isLoading
              ? Center(child: CircularProgressIndicator(color: _brandColor))
              : dataService.activities.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20)]
                            ),
                            child: Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[300]),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            l10n.msgNoActivitiesTitle, 
                            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.msgNoActivitiesBody,
                            style: TextStyle(color: Colors.grey[400]),
                          ), 
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: dataService.refresh, 
                    color: _brandColor,
                    backgroundColor: Colors.white,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      itemCount: dataService.activities.length,
                      itemBuilder: (context, index) {
                        final activity = dataService.activities[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: ActivityCard(
                            activity: activity,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ActivityDetailScreen(activity: activity),
                                ),
                              );
                            },
                          ),
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
        backgroundColor: _brandColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
    );
  }
}