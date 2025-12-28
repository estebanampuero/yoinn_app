import * as functions from "firebase-functions/v1"; 
import * as admin from "firebase-admin";

// Inicializar Firebase Admin
admin.initializeApp();
const db = admin.firestore();
const fcm = admin.messaging();

/**
 * Envia una notificacion Push a un dispositivo especifico.
 * (Mantenido para usar en solicitudes individuales)
 */
async function sendPushNotification(
  userId: string,
  title: string,
  body: string,
  data: any
) {
  try {
    const userDoc = await db.collection("users").doc(userId).get();
    const userData = userDoc.data();

    if (userData && userData.fcmToken) {
      const message = {
        notification: {
          title: title,
          body: body,
        },
        data: {
          ...data,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        token: userData.fcmToken,
      };

      await fcm.send(message);
      console.log(`Notificacion enviada a ${userId}`);
    } else {
      console.log(`Usuario ${userId} sin fcmToken.`);
    }
  } catch (error) {
    console.error("Error enviando push:", error);
  }
}

/**
 * Guarda una notificacion en la coleccion del usuario.
 */
async function saveInAppNotification(
  userId: string,
  message: string,
  type: string,
  relatedId: string
) {
  try {
    await db.collection("users")
      .doc(userId)
      .collection("notifications")
      .add({
        message: message,
        type: type,
        relatedId: relatedId,
        read: false,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
  } catch (error) {
    console.error("Error guardando notificacion in-app:", error);
  }
}

// 1. Trigger: Nueva Solicitud (SIN CAMBIOS)
export const onNewApplication = functions.firestore
  .document("applications/{appId}")
  .onCreate(async (snap: functions.firestore.QueryDocumentSnapshot, context: functions.EventContext) => {
    const appData = snap.data();
    const activityId = appData.activityId;

    const activityDoc = await db.collection("activities")
      .doc(activityId)
      .get();
    
    const hostUid = activityDoc.data()?.hostUid;
    const title = activityDoc.data()?.title;

    if (hostUid) {
      const msg = `${appData.applicantName} quiere unirse a "${title}"`;
      
      await sendPushNotification(
        hostUid,
        "Nueva Solicitud",
        msg,
        {type: "application", relatedActivityId: activityId}
      );
      
      await saveInAppNotification(
        hostUid,
        msg,
        "application",
        activityId
      );
    }
  });

// 2. Trigger: Cambio de Estado - Aceptado (SIN CAMBIOS)
export const onApplicationStatusChange = functions.firestore
  .document("applications/{appId}")
  .onUpdate(async (change: functions.Change<functions.firestore.QueryDocumentSnapshot>, context: functions.EventContext) => {
    const newData = change.after.data();
    const oldData = change.before.data();

    if (newData.status === "accepted" && oldData.status !== "accepted") {
      const activityDoc = await db.collection("activities")
        .doc(newData.activityId)
        .get();
        
      const title = activityDoc.data()?.title;
      const msg = `¡Fuiste aceptado en "${title}"!`;

      await sendPushNotification(
        newData.applicantUid,
        "Solicitud Aceptada",
        msg,
        {type: "application", relatedActivityId: newData.activityId}
      );

      await saveInAppNotification(
        newData.applicantUid,
        msg,
        "application",
        newData.activityId
      );
    }
  });

// 3. Trigger: Nuevo Mensaje de Chat (MEJORADO - GRUPAL)
export const onNewChatMessage = functions.firestore
  .document("activities/{activityId}/messages/{msgId}")
  .onCreate(async (snap: functions.firestore.QueryDocumentSnapshot, context: functions.EventContext) => {
    const msgData = snap.data();
    const activityId = context.params.activityId;

    // Datos del mensaje
    const senderUid = msgData.senderUid;
    const senderName = msgData.senderName || "Alguien";
    const text = msgData.text || "Envió un mensaje";

    try {
      // A. Obtener datos de la Actividad
      const activityDoc = await db.collection("activities").doc(activityId).get();
      if (!activityDoc.exists) return;

      const activityData = activityDoc.data();
      const activityTitle = activityData?.title || "Chat Actividad";
      const hostUid = activityData?.hostUid;

      // B. Buscar participantes ACEPTADOS
      const applicationsSnapshot = await db.collection("applications")
        .where("activityId", "==", activityId)
        .where("status", "==", "accepted")
        .get();

      // C. Crear lista de UIDs destinatarios (Set evita duplicados)
      const recipientUids = new Set<string>();

      // Agregar al Host (si no es quien envió)
      if (hostUid && hostUid !== senderUid) {
        recipientUids.add(hostUid);
      }

      // Agregar participantes aceptados (si no son quien envió)
      applicationsSnapshot.forEach((doc) => {
        const data = doc.data();
        if (data.applicantUid && data.applicantUid !== senderUid) {
          recipientUids.add(data.applicantUid);
        }
      });

      if (recipientUids.size === 0) {
        console.log("Nadie a quien notificar en el chat.");
        return;
      }

      // D. Buscar Tokens FCM de los destinatarios
      const tokens: string[] = [];
      const userReads: Promise<FirebaseFirestore.DocumentSnapshot>[] = [];

      recipientUids.forEach((uid) => {
        userReads.push(db.collection("users").doc(uid).get());
      });

      const userDocs = await Promise.all(userReads);

      userDocs.forEach((doc) => {
        if (doc.exists) {
          const userData = doc.data();
          if (userData?.fcmToken) {
            tokens.push(userData.fcmToken);
          }
        }
      });

      if (tokens.length === 0) return;

      // E. Enviar Notificación Multicast (Más eficiente para grupos)
      const payload: admin.messaging.MulticastMessage = {
        tokens: tokens,
        notification: {
          title: activityTitle,
          body: `${senderName}: ${text}`,
        },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          type: "chat_message",
          relatedActivityId: activityId, // Usamos relatedActivityId para consistencia
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
            },
          },
        },
      };

      const response = await fcm.sendEachForMulticast(payload);
      console.log(`Chat: ${response.successCount} notificaciones enviadas.`);

    } catch (error) {
      console.error("Error en onNewChatMessage:", error);
    }
  });