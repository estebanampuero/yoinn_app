/**
 * Lógica de Notificaciones Yoinn - SOPORTE MULTI-IDIOMA
 * Fecha: 02 Ene 2026
 * MODIFICADO: Configuración robusta de Sonido/Prioridad para iOS y Android
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
    const text = messageData.text || "📷 Imagen enviada"; 

    try {
        const activityDoc = await admin.firestore().collection('activities').doc(activityId).get();
        if (!activityDoc.exists) return;
        
        const activityData = activityDoc.data();
        const hostUid = activityData.hostUid;
        const activityTitle = activityData.title || "Actividad";

        const appsSnapshot = await admin.firestore().collection('applications')
            .where('activityId', '==', activityId)
            .where('status', '==', 'accepted').get();

        let uidsToNotify = new Set();
        if (hostUid && hostUid !== senderUid) uidsToNotify.add(hostUid);
        
        appsSnapshot.forEach(doc => {
            if (doc.data().applicantUid !== senderUid) uidsToNotify.add(doc.data().applicantUid);
        });

        const promises = [];
        
        for (let uid of uidsToNotify) {
            const userDocPromise = admin.firestore().collection('users').doc(uid).get().then(userDoc => {
                if (!userDoc.exists) return;

                const userData = userDoc.data();
                const token = userData.fcmToken;
                const lang = userData.languageCode || 'es'; 

                let notifTitle, notifBody;
                
                if (lang === 'en') {
                    notifTitle = `New message in "${activityTitle}"`;
                    notifBody = messageData.text || "📷 Image sent";
                } else {
                    notifTitle = `Nuevo mensaje en "${activityTitle}"`;
                    notifBody = messageData.text || "📷 Imagen enviada";
                }

                // Guardar en Firestore (Campanita)
                const dbPromise = admin.firestore().collection('users').doc(uid).collection('notifications').add({
                    title: notifTitle,
                    body: notifBody,
                    type: 'chat',
                    activityId: activityId,
                    read: false,
                    timestamp: admin.firestore.FieldValue.serverTimestamp()
                });
                
                // Enviar Push (FCM)
                let pushPromise = Promise.resolve();
                if (token) {
                    const message = {
                        token: token, 
                        // General (Visualización básica)
                        notification: {
                            title: `💬 ${activityTitle}`,
                            body: notifBody,
                        },
                        data: {
                            type: "chat",
                            activityId: activityId,
                            click_action: "FLUTTER_NOTIFICATION_CLICK"
                        },
                        // Configuración ANDROID (Canal y Prioridad)
                        android: {
                            priority: "high",
                            notification: {
                                sound: "default",
                                channelId: "high_importance_channel_v2",
                                clickAction: "FLUTTER_NOTIFICATION_CLICK"
                            }
                        },
                        // Configuración iOS (Prioridad Máxima y Sonido)
                        apns: {
                            headers: {
                                "apns-priority": "10" // Crítico para que suene en segundo plano
                            },
                            payload: {
                                aps: {
                                    sound: "default"
                                }
                            }
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

// --- 2. NUEVA SOLICITUD ---
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

        const hostUserDoc = await admin.firestore().collection('users').doc(hostUid).get();
        if (!hostUserDoc.exists) return;

        const hostData = hostUserDoc.data();
        const lang = hostData.languageCode || 'es';
        const token = hostData.fcmToken;

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

        // Guardar en Firestore
        await admin.firestore().collection('users').doc(hostUid).collection('notifications').add({
            title: titleDB,
            body: bodyDB,
            type: 'request_join', 
            activityId: activityId,
            applicantUid: applicantUid,
            read: false,
            timestamp: admin.firestore.FieldValue.serverTimestamp()
        });

        // Enviar Push
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
                },
                // Configuración ANDROID
                android: {
                    priority: "high",
                    notification: {
                        sound: "default",
                        channelId: "high_importance_channel_v2",
                        clickAction: "FLUTTER_NOTIFICATION_CLICK"
                    }
                },
                // Configuración iOS
                apns: {
                    headers: { "apns-priority": "10" },
                    payload: {
                        aps: {
                            sound: "default"
                        }
                    }
                }
            };
            await admin.messaging().send(message);
        }
    } catch (error) {
        console.error("Error en application notification:", error);
    }
});

// --- 3. SOLICITUD ACEPTADA ---
exports.onApplicationAccepted = onDocumentUpdated("applications/{applicationId}", async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    if (before.status !== 'accepted' && after.status === 'accepted') {
        const applicantUid = after.applicantUid;
        const activityId = after.activityId;

        try {
            const activityDoc = await admin.firestore().collection('activities').doc(activityId).get();
            const activityTitle = activityDoc.data()?.title || "Actividad";

            const userDoc = await admin.firestore().collection('users').doc(applicantUid).get();
            if (!userDoc.exists) return;

            const userData = userDoc.data();
            const lang = userData.languageCode || 'es';
            const token = userData.fcmToken;

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

            // Guardar en Firestore
            await admin.firestore().collection('users').doc(applicantUid).collection('notifications').add({
                title: titleDB,
                body: bodyDB,
                type: 'request_accepted',
                activityId: activityId,
                read: false,
                timestamp: admin.firestore.FieldValue.serverTimestamp()
            });

            // Enviar Push
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
                    },
                    // Configuración ANDROID
                    android: {
                        priority: "high",
                        notification: {
                            sound: "default",
                            channelId: "high_importance_channel_v2",
                            clickAction: "FLUTTER_NOTIFICATION_CLICK"
                        }
                    },
                    // Configuración iOS
                    apns: {
                        headers: { "apns-priority": "10" },
                        payload: {
                            aps: {
                                sound: "default"
                            }
                        }
                    }
                };
                await admin.messaging().send(message);
            }
        } catch (error) {
            console.error("Error en accepted notification:", error);
        }
    }
});