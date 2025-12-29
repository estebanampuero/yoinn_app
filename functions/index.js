/**
 * Lógica de Notificaciones Yoinn - VERSIÓN CORREGIDA JS
 * Fecha: 29 Dic 2025
 */

const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2/options");
const admin = require("firebase-admin");

admin.initializeApp();

// CONFIGURACIÓN REGIONAL: Santiago, Chile
setGlobalOptions({ 
    maxInstances: 10,
    region: "southamerica-west1" 
});

// --- 1. NOTIFICACIÓN DE CHAT (Nuevo nombre: onNewChatMessage) ---
exports.onNewChatMessage = onDocumentCreated("activities/{activityId}/messages/{messageId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const messageData = snapshot.data();
    const activityId = event.params.activityId;
    const senderUid = messageData.senderUid;
    const text = messageData.text || "📷 Imagen enviada";

    try {
        const activityDoc = await admin.firestore().collection('activities').doc(activityId).get();
        if (!activityDoc.exists) return;
        
        const activityData = activityDoc.data();
        const hostUid = activityData.hostUid;
        const activityTitle = activityData.title || "Actividad";

        // Buscar a quién notificar (Host + Participantes Aceptados)
        const appsSnapshot = await admin.firestore().collection('applications')
            .where('activityId', '==', activityId)
            .where('status', '==', 'accepted').get();

        let uidsToNotify = new Set();
        // Incluir al host si no fue él quien escribió
        if (hostUid && hostUid !== senderUid) uidsToNotify.add(hostUid);
        
        // Incluir participantes
        appsSnapshot.forEach(doc => {
            if (doc.data().applicantUid !== senderUid) uidsToNotify.add(doc.data().applicantUid);
        });

        const promises = [];
        for (let uid of uidsToNotify) {
            // A. Guardar en "Campanita" (Firestore)
            const dbPromise = admin.firestore().collection('users').doc(uid).collection('notifications').add({
                title: `Nuevo mensaje en "${activityTitle}"`,
                body: text,
                type: 'chat',
                activityId: activityId,
                read: false,
                timestamp: admin.firestore.FieldValue.serverTimestamp()
            });
            promises.push(dbPromise);

            // B. Enviar Push (FCM) - MÉTODO .send() CORREGIDO
            const userPushPromise = admin.firestore().collection('users').doc(uid).get().then(userDoc => {
                const token = userDoc.data()?.fcmToken;
                if (token) {
                    const message = {
                        token: token, 
                        notification: {
                            title: `💬 ${activityTitle}`,
                            body: text,
                        },
                        data: {
                            type: "chat",
                            activityId: activityId,
                            click_action: "FLUTTER_NOTIFICATION_CLICK"
                        }
                    };
                    // Usamos .send() en lugar de .sendToDevice()
                    return admin.messaging().send(message);
                }
            });
            promises.push(userPushPromise);
        }
        await Promise.all(promises);
        console.log(`Chat notificado a ${uidsToNotify.size} usuarios.`);

    } catch (error) {
        console.error("Error en chat notification:", error);
    }
});

// --- 2. NUEVA SOLICITUD (Alguien quiere unirse) ---
exports.onNewApplication = onDocumentCreated("applications/{applicationId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;
    
    const data = snapshot.data();
    const activityId = data.activityId;
    const applicantName = data.applicantName || "Alguien";
    const applicantUid = data.applicantUid;

    try {
        const activityDoc = await admin.firestore().collection('activities').doc(activityId).get();
        if (!activityDoc.exists) return;

        const hostUid = activityDoc.data().hostUid;
        const activityTitle = activityDoc.data().title;

        if (hostUid === applicantUid) return;

        // A. Guardar en Campanita
        await admin.firestore().collection('users').doc(hostUid).collection('notifications').add({
            title: "Nueva Solicitud",
            body: `${applicantName} quiere unirse a "${activityTitle}"`,
            type: 'request_join', 
            activityId: activityId,
            applicantUid: applicantUid,
            read: false,
            timestamp: admin.firestore.FieldValue.serverTimestamp()
        });

        // B. Enviar Push - CORREGIDO
        const hostUserDoc = await admin.firestore().collection('users').doc(hostUid).get();
        const token = hostUserDoc.data()?.fcmToken;
        
        if (token) {
            const message = {
                token: token,
                notification: {
                    title: "🙋‍♂️ Nueva Solicitud",
                    body: `${applicantName} quiere unirse a tu actividad`,
                },
                data: {
                    type: "request_join",
                    activityId: activityId,
                    click_action: "FLUTTER_NOTIFICATION_CLICK"
                }
            };
            await admin.messaging().send(message);
        }
    } catch (error) {
        console.error("Error en application notification:", error);
    }
});

// --- 3. SOLICITUD ACEPTADA (Notificar al participante) ---
exports.onApplicationAccepted = onDocumentUpdated("applications/{applicationId}", async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    if (before.status !== 'accepted' && after.status === 'accepted') {
        const applicantUid = after.applicantUid;
        const activityId = after.activityId;

        try {
            const activityDoc = await admin.firestore().collection('activities').doc(activityId).get();
            const activityTitle = activityDoc.data()?.title || "Actividad";

            // A. Guardar en Campanita
            await admin.firestore().collection('users').doc(applicantUid).collection('notifications').add({
                title: "¡Solicitud Aceptada!",
                body: `Ya eres parte de "${activityTitle}".`,
                type: 'request_accepted',
                activityId: activityId,
                read: false,
                timestamp: admin.firestore.FieldValue.serverTimestamp()
            });

            // B. Enviar Push - CORREGIDO
            const userDoc = await admin.firestore().collection('users').doc(applicantUid).get();
            const token = userDoc.data()?.fcmToken;
            
            if (token) {
                const message = {
                    token: token,
                    notification: {
                        title: "🚀 ¡Estás dentro!",
                        body: `Te aceptaron en "${activityTitle}"`,
                    },
                    data: {
                        type: "request_accepted",
                        activityId: activityId,
                        click_action: "FLUTTER_NOTIFICATION_CLICK"
                    }
                };
                await admin.messaging().send(message);
            }
        } catch (error) {
            console.error("Error en accepted notification:", error);
        }
    }
});