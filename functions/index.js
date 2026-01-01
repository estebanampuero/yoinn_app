/**
 * Lógica de Notificaciones Yoinn - SOPORTE MULTI-IDIOMA
 * Fecha: 01 Ene 2026
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

// --- 1. NOTIFICACIÓN DE CHAT ---
exports.onNewChatMessage = onDocumentCreated("activities/{activityId}/messages/{messageId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const messageData = snapshot.data();
    const activityId = event.params.activityId;
    const senderUid = messageData.senderUid;
    const text = messageData.text || "📷 Imagen enviada"; // Fallback por defecto, se traducirá abajo si es imagen

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
        if (hostUid && hostUid !== senderUid) uidsToNotify.add(hostUid);
        
        appsSnapshot.forEach(doc => {
            if (doc.data().applicantUid !== senderUid) uidsToNotify.add(doc.data().applicantUid);
        });

        const promises = [];
        
        // Iteramos usuarios para detectar su idioma individualmente
        for (let uid of uidsToNotify) {
            // Obtenemos el usuario ANTES para saber su idioma
            const userDocPromise = admin.firestore().collection('users').doc(uid).get().then(userDoc => {
                if (!userDoc.exists) return;

                const userData = userDoc.data();
                const token = userData.fcmToken;
                const lang = userData.languageCode || 'es'; // Por defecto Español

                // Definir textos según idioma
                let notifTitle, notifBody;
                
                if (lang === 'en') {
                    notifTitle = `New message in "${activityTitle}"`;
                    notifBody = messageData.text || "📷 Image sent";
                } else {
                    notifTitle = `Nuevo mensaje en "${activityTitle}"`;
                    notifBody = messageData.text || "📷 Imagen enviada";
                }

                // A. Guardar en "Campanita" (Firestore)
                const dbPromise = admin.firestore().collection('users').doc(uid).collection('notifications').add({
                    title: notifTitle,
                    body: notifBody,
                    type: 'chat',
                    activityId: activityId,
                    read: false,
                    timestamp: admin.firestore.FieldValue.serverTimestamp()
                });
                
                // B. Enviar Push (FCM) si tiene token
                let pushPromise = Promise.resolve();
                if (token) {
                    const message = {
                        token: token, 
                        notification: {
                            title: `💬 ${activityTitle}`,
                            body: notifBody,
                        },
                        data: {
                            type: "chat",
                            activityId: activityId,
                            click_action: "FLUTTER_NOTIFICATION_CLICK"
                        }
                    };
                    pushPromise = admin.messaging().send(message);
                }

                return Promise.all([dbPromise, pushPromise]);
            });

            promises.push(userDocPromise);
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

        // Obtener datos del Host para saber idioma
        const hostUserDoc = await admin.firestore().collection('users').doc(hostUid).get();
        if (!hostUserDoc.exists) return;

        const hostData = hostUserDoc.data();
        const lang = hostData.languageCode || 'es';
        const token = hostData.fcmToken;

        // Definir textos
        let titleDB, bodyDB, titlePush, bodyPush;

        if (lang === 'en') {
            titleDB = "New Request";
            bodyDB = `${applicantName} wants to join "${activityTitle}"`;
            titlePush = "🙋‍♂️ New Request";
            bodyPush = `${applicantName} wants to join your activity`;
        } else {
            titleDB = "Nueva Solicitud";
            bodyDB = `${applicantName} quiere unirse a "${activityTitle}"`;
            titlePush = "🙋‍♂️ Nueva Solicitud";
            bodyPush = `${applicantName} quiere unirse a tu actividad`;
        }

        // A. Guardar en Campanita
        await admin.firestore().collection('users').doc(hostUid).collection('notifications').add({
            title: titleDB,
            body: bodyDB,
            type: 'request_join', 
            activityId: activityId,
            applicantUid: applicantUid,
            read: false,
            timestamp: admin.firestore.FieldValue.serverTimestamp()
        });

        // B. Enviar Push
        if (token) {
            const message = {
                token: token,
                notification: {
                    title: titlePush,
                    body: bodyPush,
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

            // Obtener datos del Participante para saber idioma
            const userDoc = await admin.firestore().collection('users').doc(applicantUid).get();
            if (!userDoc.exists) return;

            const userData = userDoc.data();
            const lang = userData.languageCode || 'es';
            const token = userData.fcmToken;

            // Definir textos
            let titleDB, bodyDB, titlePush, bodyPush;

            if (lang === 'en') {
                titleDB = "Request Accepted!";
                bodyDB = `You are now part of "${activityTitle}".`;
                titlePush = "🚀 You're in!";
                bodyPush = `You were accepted into "${activityTitle}"`;
            } else {
                titleDB = "¡Solicitud Aceptada!";
                bodyDB = `Ya eres parte de "${activityTitle}".`;
                titlePush = "🚀 ¡Estás dentro!";
                bodyPush = `Te aceptaron en "${activityTitle}"`;
            }

            // A. Guardar en Campanita
            await admin.firestore().collection('users').doc(applicantUid).collection('notifications').add({
                title: titleDB,
                body: bodyDB,
                type: 'request_accepted',
                activityId: activityId,
                read: false,
                timestamp: admin.firestore.FieldValue.serverTimestamp()
            });

            // B. Enviar Push
            if (token) {
                const message = {
                    token: token,
                    notification: {
                        title: titlePush,
                        body: bodyPush,
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