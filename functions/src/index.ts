import * as functions from "firebase-functions/v1"; // <-- FORZAMOS V1
import * as admin from "firebase-admin";

// Inicializar Firebase Admin
admin.initializeApp();
const db = admin.firestore();
const fcm = admin.messaging();

/**
 * Envia una notificacion Push a un dispositivo especifico.
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

// 1. Trigger: Nueva Solicitud
export const onNewApplication = functions.firestore
  .document("applications/{appId}")
  // Agregamos tipos explícitos a 'snap' y 'context'
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
        {type: "application", activityId}
      );
      
      await saveInAppNotification(
        hostUid,
        msg,
        "application",
        activityId
      );
    }
  });

// 2. Trigger: Cambio de Estado (Aceptado)
export const onApplicationStatusChange = functions.firestore
  .document("applications/{appId}")
  // Agregamos tipos explícitos a 'change' y 'context'
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
        {type: "application", activityId: newData.activityId}
      );

      await saveInAppNotification(
        newData.applicantUid,
        msg,
        "application",
        newData.activityId
      );
    }
  });

// 3. Trigger: Nuevo Mensaje de Chat
export const onNewChatMessage = functions.firestore
  .document("activities/{activityId}/messages/{msgId}")
  // Agregamos tipos explícitos
  .onCreate(async (snap: functions.firestore.QueryDocumentSnapshot, context: functions.EventContext) => {
    const msgData = snap.data();
    const activityId = context.params.activityId;

    const activityDoc = await db.collection("activities")
      .doc(activityId)
      .get();

    const hostUid = activityDoc.data()?.hostUid;
    const title = activityDoc.data()?.title;

    // Si no soy el dueño y escribo, le aviso al dueño
    if (msgData.senderUid !== hostUid && hostUid) {
      const body = `${msgData.senderName}: ${msgData.text}`;
      
      await sendPushNotification(
        hostUid,
        `Nuevo mensaje en ${title}`,
        body,
        {type: "chat", activityId}
      );
    }
  });