/**
 * Lógica para Notificaciones de Chat en Yoinn App (Versión 2 - Moderna)
 */

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2/options");
const admin = require("firebase-admin");

// Inicializamos la app
admin.initializeApp();

// CONFIGURACIÓN GLOBAL
// Aquí forzamos la región a Chile (southamerica-west1) para que coincida con tu base de datos
setGlobalOptions({ 
    maxInstances: 10,
    region: "southamerica-west1" 
});

exports.sendChatNotification = onDocumentCreated("activities/{activityId}/messages/{messageId}", async (event) => {
    // En v2, 'event.data' es el snapshot y 'event.params' tiene los IDs
    const snapshot = event.data;
    
    // Si no hay datos (ej. borrado), salimos
    if (!snapshot) {
        return;
    }

    const messageData = snapshot.data();
    const activityId = event.params.activityId;

    const senderName = messageData.senderName || "Alguien";
    const text = messageData.text || "Envió una imagen"; 
    const senderUid = messageData.senderUid;

    try {
      // 1. Obtener datos de la Actividad
      const activityDoc = await admin.firestore().collection('activities').doc(activityId).get();
      if (!activityDoc.exists) {
        console.log("Actividad no encontrada");
        return;
      }
      
      const activityData = activityDoc.data();
      const hostUid = activityData.hostUid;
      const activityTitle = activityData.title || "Actividad";

      // 2. Buscar participantes ACEPTADOS
      const appsSnapshot = await admin.firestore()
          .collection('applications') 
          .where('activityId', '==', activityId)
          .where('status', '==', 'accepted')
          .get();

      // 3. Filtrar a quién notificar
      let uidsToNotify = new Set();
      
      // A. Incluir al dueño (si no es quien escribió)
      if (hostUid && hostUid !== senderUid) {
        uidsToNotify.add(hostUid);
      }

      // B. Incluir participantes (si no son quien escribió)
      appsSnapshot.forEach(doc => {
        const participantUid = doc.data().applicantUid;
        if (participantUid && participantUid !== senderUid) {
          uidsToNotify.add(participantUid);
        }
      });

      if (uidsToNotify.size === 0) {
        console.log("Nadie a quien notificar");
        return;
      }

      // 4. Obtener tokens FCM
      const tokens = [];
      for (let uid of uidsToNotify) {
        const userDoc = await admin.firestore().collection('users').doc(uid).get();
        const token = userDoc.data()?.fcmToken;
        if (token) {
          tokens.push(token);
        }
      }

      if (tokens.length === 0) {
        console.log("No hay tokens registrados");
        return;
      }

      // 5. Crear Payload
      const payload = {
        notification: {
          title: `Nuevo mensaje en "${activityTitle}"`,
          body: `${senderName}: ${text}`,
          sound: "default",
        },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          activityId: activityId,
          type: "chat_message"
        },
      };

      // 6. Enviar
      const response = await admin.messaging().sendToDevice(tokens, payload);
      console.log("Notificaciones enviadas:", response.successCount);

    } catch (error) {
      console.error("Error enviando notificación:", error);
    }
});