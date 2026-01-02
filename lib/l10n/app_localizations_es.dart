// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Yoinn';

  @override
  String get navActivities => 'Actividades';

  @override
  String get navMap => 'Mapa';

  @override
  String get navAlerts => 'Alertas';

  @override
  String get navProfile => 'Perfil';

  @override
  String get exploreCityTitle => 'Explora tu Ciudad';

  @override
  String get exploreCityText =>
      'Crea y descubre actividades y eventos únicos que suceden a tu alrededor en tiempo real.';

  @override
  String get joinActivityTitle => 'Únete a la actividad';

  @override
  String get joinActivityText =>
      'Solicita unirte a planes de deporte, comida, fiestas y más con un solo toque.';

  @override
  String get connectChatTitle => 'Conecta y Chatea';

  @override
  String get connectChatText =>
      'Conoce gente nueva, chatea con el grupo y vive experiencias reales.';

  @override
  String get continueWithGoogle => 'Continuar con Google';

  @override
  String get continueWithApple => 'Continuar con Apple';

  @override
  String get demoAccessLabel => 'Acceso Demo / Admin';

  @override
  String get emailDemoLabel => 'Email Demo';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get enterButton => 'Ingresar';

  @override
  String get termsAndConditionsText =>
      'Al continuar, aceptas nuestros Términos de Servicio\ny Política de Privacidad.';

  @override
  String get logout => 'Cerrar Sesión';

  @override
  String get searchPlaceholder => 'Buscar...';

  @override
  String get catAll => 'Todas';

  @override
  String get catSport => 'Deporte';

  @override
  String get catFood => 'Comida';

  @override
  String get catArt => 'Arte';

  @override
  String get catParty => 'Fiesta';

  @override
  String get catOutdoor => 'Viaje';

  @override
  String get catGames => 'Juegos';

  @override
  String get catOther => 'Otros';

  @override
  String get hostedBy => 'Organiza:';

  @override
  String get spotsLeft => 'cupos';

  @override
  String get goingCount => 'van';

  @override
  String get joinButton => 'Unirme';

  @override
  String get viewDetails => 'Ver Detalles';

  @override
  String get activityGroup => 'Actividad Grupal';

  @override
  String get radiusLabel => 'Radio de búsqueda';

  @override
  String get kmUnit => 'km';

  @override
  String get chatPlaceholder => 'Escribe un mensaje...';

  @override
  String get sendButton => 'Enviar';

  @override
  String get noMessages => 'Aún no hay mensajes. ¡Di hola!';

  @override
  String get createActivityTitle => 'Crear Panorama';

  @override
  String get fieldTitle => 'Título de la actividad';

  @override
  String get fieldDesc => 'Descripción';

  @override
  String get fieldDate => 'Fecha';

  @override
  String get fieldTime => 'Hora';

  @override
  String get fieldLocation => 'Ubicación';

  @override
  String get fieldSpots => 'Cupos disponibles';

  @override
  String get createButton => 'Publicar';

  @override
  String get errorGeneric => 'Ocurrió un error';

  @override
  String get errorAppleLogin => 'Error al iniciar sesión con Apple';

  @override
  String get successMessage => '¡Éxito!';

  @override
  String get loading => 'Cargando...';

  @override
  String get dialogUseTicketTitle => '¿Usar 1 Ticket?';

  @override
  String get dialogUseTicketBody =>
      'Estás a punto de usar 1 de tus tickets semanales para postular a esta actividad.';

  @override
  String dialogTicketsRemaining(Object count) {
    return 'Te quedarán: $count tickets';
  }

  @override
  String get btnUseTicket => 'USAR TICKET';

  @override
  String get btnCancel => 'Cancelar';

  @override
  String get msgRequestSent => '¡Solicitud enviada! Ticket usado.';

  @override
  String get msgGoPro => 'Hazte PRO para unirte a más actividades.';

  @override
  String get dialogDeleteTitle => 'Eliminar Actividad';

  @override
  String get dialogDeleteBody =>
      '¿Estás seguro? Esta acción no se puede deshacer.';

  @override
  String get btnDelete => 'Eliminar';

  @override
  String get msgActivityDeleted => 'Actividad eliminada';

  @override
  String get shareMessageIntro =>
      '¡Hey! 🌟 Encontré esta actividad en Yoinn y pensé que te gustaría:';

  @override
  String get shareMessageCta =>
      '👇 Toca aquí para ver detalles o descargar la app:';

  @override
  String get optShare => 'Compartir Actividad';

  @override
  String get optEdit => 'Editar Actividad';

  @override
  String get optDelete => 'Eliminar';

  @override
  String get optReport => 'Reportar';

  @override
  String get optBlock => 'Bloquear Usuario';

  @override
  String get dialogReportTitle => 'Reportar Actividad';

  @override
  String get dialogReportBody => '¿Por qué quieres reportar esto?';

  @override
  String get reasonSpam => 'Es Spam';

  @override
  String get reasonOffensive => 'Contenido Ofensivo';

  @override
  String get msgReportThanks =>
      'Gracias. Revisaremos este contenido en menos de 24h.';

  @override
  String get msgReportError => 'Error al enviar reporte.';

  @override
  String get dialogBlockTitle => 'Bloquear Usuario';

  @override
  String get dialogBlockBody =>
      'No verás más contenido de este usuario. ¿Continuar?';

  @override
  String get btnBlock => 'BLOQUEAR';

  @override
  String get msgUserBlocked => 'Usuario bloqueado.';

  @override
  String get lblAboutActivity => 'Sobre la actividad';

  @override
  String get lblConfirmedAttendees => 'Asistentes Confirmados';

  @override
  String get btnGoToChat => 'Ir al Chat del Grupo';

  @override
  String get btnManageRequests => 'Gestionar Solicitudes';

  @override
  String get btnYouAreIn => '¡Estás dentro! Ir al Chat';

  @override
  String get btnRequestPending => 'Solicitud enviada...';

  @override
  String get btnSoldOut => 'AGOTADO';

  @override
  String get btnRequestJoin => 'Solicitar Unirme';

  @override
  String get screenCreateTitle => 'Crear Nueva Actividad';

  @override
  String get lblPhotoHeader => 'Foto de la actividad';

  @override
  String get lblTapToUpload => 'Toca para subir una imagen';

  @override
  String get lblCategory => 'Categoría';

  @override
  String get lblMaxAttendees => 'Nº de acompañantes (máx)';

  @override
  String get btnReady => 'Listo';

  @override
  String get btnPublish => 'Publicar Actividad';

  @override
  String get hintTitle => 'Ej: Tarde de Senderismo';

  @override
  String get hintDesc => 'Cuéntanos de qué trata...';

  @override
  String get hintLocation => 'Toca para buscar en el mapa...';

  @override
  String get msgSelectLocation =>
      'Por favor toca en \"Ubicación\" para seleccionar en el mapa';

  @override
  String get msgActivityCreated => '¡Actividad creada con éxito!';

  @override
  String get errImageUpload => 'No se pudo subir la imagen';

  @override
  String get personSingular => 'persona';

  @override
  String get personPlural => 'personas';

  @override
  String get tabUsers => 'Usuarios';

  @override
  String get tabActivities => 'Actividades';

  @override
  String get tabReports => 'Reportes';

  @override
  String get msgNoUsers => 'No se encontraron usuarios.';

  @override
  String get msgNoActivities => 'No se encontraron actividades.';

  @override
  String get msgNoReports => '¡Sin reportes pendientes!';

  @override
  String get dialogDeleteUserTitle => 'Eliminar Usuario';

  @override
  String dialogDeleteUserBody(Object name) {
    return '¿Eliminar a $name permanentemente?';
  }

  @override
  String get dialogSanctionTitle => 'Confirmar Sanción';

  @override
  String get dialogSanctionBody =>
      'Esto eliminará la actividad reportada y cerrará el reporte. ¿Proceder?';

  @override
  String get btnDeleteAll => 'BORRAR TODO';

  @override
  String get btnDismiss => 'Descartar (Falso)';

  @override
  String get lblReportedActivity => 'ACTIVIDAD REPORTADA';

  @override
  String get lblReason => 'Motivo:';

  @override
  String get lblTapDetails => 'Toca para revisar detalles';

  @override
  String get msgContentDeleted => 'Contenido eliminado por moderación';

  @override
  String get msgReportDismissed => 'Reporte descartado';

  @override
  String get msgActivityLoading => 'Cargando actividad...';

  @override
  String get msgActivityNotFound =>
      'La actividad no existe (posiblemente ya fue eliminada).';

  @override
  String get lblTypingSingle => 'Alguien está escribiendo...';

  @override
  String get lblTypingMultiple => 'Varios están escribiendo...';

  @override
  String get msgEmptyChatTitle => '¡Saluda al grupo!';

  @override
  String get msgEmptyChatBody => 'Sé el primero en romper el hielo.';

  @override
  String get screenEditActivityTitle => 'Editar Actividad';

  @override
  String get btnSaveChanges => 'Guardar Cambios';

  @override
  String get msgActivityUpdated => '¡Actividad actualizada con éxito!';

  @override
  String get msgActivityRenewed =>
      'Actividad renovada y cupos reiniciados correctamente.';

  @override
  String get msgSelectLocationVerify =>
      'Por favor toca en \"Ubicación\" para verificar en el mapa';

  @override
  String get screenEditProfileTitle => 'Editar Perfil';

  @override
  String get btnSave => 'GUARDAR';

  @override
  String get lblName => 'Nombre';

  @override
  String get lblBio => 'Biografía';

  @override
  String get lblInstagram => 'Usuario de Instagram (Opcional)';

  @override
  String get lblInterests => 'Intereses / Hobbies';

  @override
  String get errNameRequired => 'El nombre es obligatorio';

  @override
  String get msgProfileUpdated => 'Perfil actualizado correctamente';

  @override
  String get msgNoActivitiesTitle => 'No se encontraron actividades';

  @override
  String get msgNoActivitiesBody =>
      'Intenta cambiar los filtros o crea una nueva';

  @override
  String get hobbySports => 'Deportes';

  @override
  String get hobbyFood => 'Comida';

  @override
  String get hobbyParty => 'Fiesta';

  @override
  String get hobbyMusic => 'Música';

  @override
  String get hobbyArt => 'Arte';

  @override
  String get hobbyOutdoors => 'Aire Libre';

  @override
  String get hobbyTech => 'Tecnología';

  @override
  String get hobbyCinema => 'Cine';

  @override
  String get hobbyGames => 'Juegos';

  @override
  String get hobbyTravel => 'Viajes';

  @override
  String get hobbyWellness => 'Bienestar';

  @override
  String get hobbyEducation => 'Educación';

  @override
  String get hobbyPets => 'Mascotas';

  @override
  String get hobbyBusiness => 'Negocios';

  @override
  String get hobbyLanguages => 'Idiomas';

  @override
  String get hobbyVolunteering => 'Voluntariado';

  @override
  String get hobbyPhotography => 'Fotografía';

  @override
  String get hobbyLiterature => 'Literatura';

  @override
  String get hobbyFamily => 'Familia';

  @override
  String get hobbyOther => 'Otro';

  @override
  String get lblSelectedLocation => 'Ubicación seleccionada';

  @override
  String get hintSearchAddress => 'Buscar dirección...';

  @override
  String get btnUseCurrentLocation => 'Usar mi ubicación actual';

  @override
  String get btnViewAddress => '🔍 Ver dirección';

  @override
  String get btnConfirmLocation => 'Confirmar Ubicación';

  @override
  String get errGpsLocation => 'No se pudo obtener la ubicación GPS';

  @override
  String screenManageRequestsTitle(Object activityTitle) {
    return 'Solicitudes para $activityTitle';
  }

  @override
  String get msgNoPendingRequests => 'No hay solicitudes pendientes';

  @override
  String get lblWantsToJoin => 'Quiere unirse';

  @override
  String msgUserAccepted(Object user) {
    return '$user aceptado';
  }

  @override
  String get screenManageParticipantsTitle => 'Gestionar Participantes';

  @override
  String get msgNoRequestsYet => 'Aún no hay solicitudes';

  @override
  String get lblPendingRequests => 'Solicitudes Pendientes';

  @override
  String get lblAcceptedParticipants => 'Participantes Aceptados';

  @override
  String get lblConfirmed => 'Confirmado';

  @override
  String get tooltipRemoveParticipant => 'Eliminar participante';

  @override
  String get dialogRemoveParticipantTitle => '¿Eliminar participante?';

  @override
  String dialogRemoveParticipantBody(Object user) {
    return '¿Estás seguro de que quieres sacar a $user de la actividad?';
  }

  @override
  String get errUserNotAuth => 'Usuario no autenticado';

  @override
  String get errImageSelect => 'Error al seleccionar imagen';

  @override
  String get paywallTitle => 'Desbloquea el Mundo';

  @override
  String get paywallSubtitle => 'Con Yoinn Premium';

  @override
  String get paywallBtnStart => 'Comenzar Ahora';

  @override
  String get paywallBtnRestore => 'Restaurar Compras';

  @override
  String get paywallLegalTerms => 'Términos de Uso';

  @override
  String get paywallLegalPrivacy => 'Privacidad';

  @override
  String get paywallPlanMonthly => 'MENSUAL';

  @override
  String get paywallPlanAnnual => 'ANUAL';

  @override
  String get paywallLabelFree => 'GRATIS';

  @override
  String get paywallLabelPro => 'PRO';

  @override
  String get paywallErrNoPlan =>
      'Error: El plan no está disponible temporalmente.';

  @override
  String get paywallErrNoPurchases => 'No se encontraron compras activas.';

  @override
  String get featRadius => 'Radio Búsqueda';

  @override
  String get featGlobal => 'Crear en otras ciudades';

  @override
  String get featGuests => 'Invitados por Evento';

  @override
  String get featJoins => 'Unirse a Eventos';

  @override
  String get featBadge => 'Insignia Verificado';

  @override
  String get valGlobalFree => '❌';

  @override
  String get valGlobalPro => 'Todo el Mundo 🌍';

  @override
  String valGuestsFree(Object count) {
    return '$count máx';
  }

  @override
  String valGuestsPro(Object count) {
    return '$count (Grupos)';
  }

  @override
  String valJoinsFree(Object count) {
    return '$count / sem';
  }

  @override
  String get valJoinsPro => 'Ilimitado ∞';

  @override
  String get valBadgeFree => '❌';

  @override
  String get valBadgePro => '✅';

  @override
  String get lblSavePercent => 'AHORRA 20%';

  @override
  String lblOnlyPricePerMonth(Object price) {
    return 'Solo $price / mes';
  }

  @override
  String get screenProfileTitle => 'Perfil';

  @override
  String get lblSearchPrefs => 'Preferencias de Búsqueda';

  @override
  String lblUnlockPro(Object km) {
    return 'Desbloquear hasta $km km';
  }

  @override
  String get lblGallery => 'Galería';

  @override
  String get lblActivities => 'Actividades';

  @override
  String get btnDeleteAccount => 'Eliminar cuenta';

  @override
  String get msgWelcomePro => '¡Bienvenido a Yoinn PRO! 🌟';

  @override
  String get bannerUpgradeTitle => 'Pásate a Yoinn PRO';

  @override
  String get bannerUpgradeSubtitle => 'Desbloquea viajes y más alcance';

  @override
  String get dialogDeleteAccountTitle => 'Eliminar Cuenta';

  @override
  String get dialogDeleteAccountBody =>
      'Esta acción es irreversible. Se borrarán tus datos y actividades.';

  @override
  String get lblTypeDelete => 'Escribe ELIMINAR para confirmar:';

  @override
  String get hintDelete => 'ELIMINAR';

  @override
  String get btnDeleteConfirm => 'BORRAR';

  @override
  String get msgProSearchFeature => 'Hazte PRO para buscar hasta 150 km 🌍';

  @override
  String get errUserNotFound => 'Usuario no encontrado';

  @override
  String errLimitReached(Object limit, Object proHint) {
    return 'Límite de actividades alcanzado ($limit). $proHint';
  }

  @override
  String get hintGoPro => 'Hazte PRO para más.';

  @override
  String errNoTickets(Object limit) {
    return 'Sin Tickets. Has usado tus $limit intentos semanales. Hazte PRO para seguir apostando.';
  }

  @override
  String get errActivityFull => 'La actividad está llena.';

  @override
  String get errActivityNotFound => 'Actividad no encontrada';

  @override
  String get errCreatingActivity => 'Error creando actividad';

  @override
  String get errEditingActivity => 'Error editando actividad';

  @override
  String get errDeletingActivity => 'Error borrando actividad';

  @override
  String get errApplying => 'Error aplicando';

  @override
  String get errAccepting => 'Error aceptando usuario';

  @override
  String get errRejecting => 'Error rechazando';

  @override
  String get errRemoving => 'Error eliminando participante';

  @override
  String get errSendingMessage => 'Error enviando mensaje';

  @override
  String get errUploadingGallery => 'Error subiendo imagen a galería';

  @override
  String get errUpdatingProfile => 'Error actualizando perfil';

  @override
  String get lblOrganizer => 'Organizador';

  @override
  String get msgActivityFull => '¡Actividad Llena!';

  @override
  String msgSpotsLeft(Object count) {
    return 'Quedan $count cupos disponibles';
  }

  @override
  String get lblEventLocation => 'Ubicación del evento';

  @override
  String lblTotalCapacity(Object count) {
    return 'Capacidad total: $count personas';
  }

  @override
  String get msgNoParticipants => 'Aún nadie se ha unido. ¡Sé el primero!';

  @override
  String get msgOnlyOneSpot => '¡Solo queda 1 cupo!';

  @override
  String msgSpotsLeftShort(Object count) {
    return '¡Solo quedan $count cupos!';
  }

  @override
  String get lblGoing => 'van';

  @override
  String get lblSpots => 'cupos';

  @override
  String get lblCreatedActivities => 'Actividades Creadas';

  @override
  String get msgNoCreatedActivities => 'No has creado actividades aún.';

  @override
  String get msgNoPhotos => 'Aún no hay fotos';

  @override
  String get tooltipAddPhoto => 'Agregar foto';

  @override
  String get msgPhotoAdded => '¡Foto agregada!';

  @override
  String get paywallLimitTitle => 'Límite Semanal Alcanzado';

  @override
  String get paywallLimitBody =>
      'Has alcanzado tus 3 uniones gratuitas de la semana. Hazte PRO para unirte a todo lo que quieras.';

  @override
  String get paywallBenefitJoins => 'Uniones Ilimitadas a eventos';

  @override
  String get paywallBenefitCreate => 'Crear eventos en cualquier país';

  @override
  String get paywallBenefitRadius => 'Radio de búsqueda de hasta 150km';

  @override
  String get lblPerMonth => '/ mes';

  @override
  String get lblCancelAnytime => 'Cancela cuando quieras';

  @override
  String get btnUnlockNow => 'DESBLOQUEAR AHORA';

  @override
  String get badgePro => 'PRO';

  @override
  String get badgeLocalGuide => '🌟 Guía Local';

  @override
  String get btnEditProfile => 'Editar Perfil';

  @override
  String get lblInterestsTitle => 'Intereses';

  @override
  String get msgLoginToViewAlerts => 'Inicia sesión para ver tus alertas';

  @override
  String get screenNotificationsTitle => 'Notificaciones';

  @override
  String get msgErrorLoadingNotifications => 'Error al cargar notificaciones';

  @override
  String get msgNoNewNotifications => 'No tienes notificaciones nuevas';

  @override
  String get lblNotificationDefaultTitle => 'Nueva Notificación';

  @override
  String get msgActivityNoLongerExists => 'Esta actividad ya no existe';

  @override
  String get msgErrorLoadingActivity => 'Error al cargar la actividad';
}
