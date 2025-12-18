import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../widgets/activity_card.dart';
import 'activity_detail_screen.dart';
import 'create_activity_screen.dart';
import 'profile_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  final List<String> _filterCategories = [
    'Todas', 'Deporte', 'Comida', 'Arte', 'Fiesta', 'Viaje', 'Musica', 'Tecnología', 'Otro', 'Bienestar'
  ];
  String _currentCategory = 'Todas';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              primary: Color(0xFF00BCD4), // Cian en calendario
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
      backgroundColor: const Color(0xFFF0F8FA), // Fondo azul muy pálido
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Yoinn",
          style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.w800, fontSize: 24),
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
                   );
                 }
              },
              child: CircleAvatar(
                backgroundImage: NetworkImage(authService.currentUser?.profilePictureUrl ?? ''),
                backgroundColor: const Color(0xFFB2EBF2), // Fondo suave si no hay foto
              ),
            ),
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
                          fillColor: const Color(0xFFE0F7FA), // Input ligeramente azulado
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
                    
                    // Botón Filtro Fecha
                    GestureDetector(
                      onTap: () => _pickDateFilter(context, dataService),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: dataService.currentFilterDate != null 
                              ? const Color(0xFF29B6F6) // Azul Brillante si activo
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
                      final isSelected = _currentCategory == category;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentCategory = category;
                          });
                          dataService.setCategoryFilter(category);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            // Fondo: Cian Profundo si seleccionado
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
        backgroundColor: const Color(0xFF00BCD4), // Cian Oscuro
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
    );
  }
}