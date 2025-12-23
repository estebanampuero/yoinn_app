class SubscriptionLimits {
  // --- USUARIO GRATIS (FREE) ---
  static const int freeMaxAttendees = 3;        // Máx invitados que pueden llevar
  static const int freeMaxActiveActivities = 1; // Máx actividades creadas a la vez
  static const int freeMaxJoinsPerWeek = 3;     // Máx actividades a las que unirse/sem

  // --- USUARIO PRO (PREMIUM) ---
  static const int proMaxAttendees = 20;        // Invitados casi ilimitados
  static const int proMaxActiveActivities = 10; 
  static const int proMaxJoinsPerWeek = 999;    // Ilimitado
}