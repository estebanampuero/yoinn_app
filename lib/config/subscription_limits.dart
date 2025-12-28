class SubscriptionLimits {
  // --- RADIO DE BÚSQUEDA (KILÓMETROS) ---
  static const double defaultRadius = 10.0;
  
  // Límite para usuarios GRATIS (30 KM)
  static const double freeMaxRadius = 30.0; 

  // Límite para usuarios PRO (150 KM)
  static const double proMaxRadius = 150.0; 

  // --- LÍMITES DE EVENTOS (ASISTENCIA) ---
  // Cuántas personas pueden ir a un evento que tú creas
  static const int freeMaxAttendees = 5;
  static const int proMaxAttendees = 20; 

  // --- LÍMITES DE CREACIÓN ---
  // Cuántas actividades activas puedes tener al mismo tiempo
  static const int freeMaxActiveActivities = 1;
  static const int proMaxActiveActivities = 10;

  // --- LÍMITES DE UNIÓN (JOIN) ---
  // A cuántas actividades puedes postular por semana (Tickets de apuesta)
  static const int freeMaxJoinsPerWeek = 3;
  static const int proMaxJoinsPerWeek = 1000; // Ilimitado
}