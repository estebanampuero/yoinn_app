"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.onNewChatMessage = exports.onApplicationStatusChange = exports.onNewApplication = void 0;
const functions = __importStar(require("firebase-functions/v1")); // <-- FORZAMOS V1
const admin = __importStar(require("firebase-admin"));
// Inicializar Firebase Admin
admin.initializeApp();
const db = admin.firestore();
const fcm = admin.messaging();
/**
 * Envia una notificacion Push a un dispositivo especifico.
 */
async function sendPushNotification(userId, title, body, data) {
    try {
        const userDoc = await db.collection("users").doc(userId).get();
        const userData = userDoc.data();
        if (userData && userData.fcmToken) {
            const message = {
                notification: {
                    title: title,
                    body: body,
                },
                data: Object.assign(Object.assign({}, data), { click_action: "FLUTTER_NOTIFICATION_CLICK" }),
                token: userData.fcmToken,
            };
            await fcm.send(message);
            console.log(`Notificacion enviada a ${userId}`);
        }
        else {
            console.log(`Usuario ${userId} sin fcmToken.`);
        }
    }
    catch (error) {
        console.error("Error enviando push:", error);
    }
}
/**
 * Guarda una notificacion en la coleccion del usuario.
 */
async function saveInAppNotification(userId, message, type, relatedId) {
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
    }
    catch (error) {
        console.error("Error guardando notificacion in-app:", error);
    }
}
// 1. Trigger: Nueva Solicitud
exports.onNewApplication = functions.firestore
    .document("applications/{appId}")
    // Agregamos tipos explícitos a 'snap' y 'context'
    .onCreate(async (snap, context) => {
    var _a, _b;
    const appData = snap.data();
    const activityId = appData.activityId;
    const activityDoc = await db.collection("activities")
        .doc(activityId)
        .get();
    const hostUid = (_a = activityDoc.data()) === null || _a === void 0 ? void 0 : _a.hostUid;
    const title = (_b = activityDoc.data()) === null || _b === void 0 ? void 0 : _b.title;
    if (hostUid) {
        const msg = `${appData.applicantName} quiere unirse a "${title}"`;
        await sendPushNotification(hostUid, "Nueva Solicitud", msg, { type: "application", activityId });
        await saveInAppNotification(hostUid, msg, "application", activityId);
    }
});
// 2. Trigger: Cambio de Estado (Aceptado)
exports.onApplicationStatusChange = functions.firestore
    .document("applications/{appId}")
    // Agregamos tipos explícitos a 'change' y 'context'
    .onUpdate(async (change, context) => {
    var _a;
    const newData = change.after.data();
    const oldData = change.before.data();
    if (newData.status === "accepted" && oldData.status !== "accepted") {
        const activityDoc = await db.collection("activities")
            .doc(newData.activityId)
            .get();
        const title = (_a = activityDoc.data()) === null || _a === void 0 ? void 0 : _a.title;
        const msg = `¡Fuiste aceptado en "${title}"!`;
        await sendPushNotification(newData.applicantUid, "Solicitud Aceptada", msg, { type: "application", activityId: newData.activityId });
        await saveInAppNotification(newData.applicantUid, msg, "application", newData.activityId);
    }
});
// 3. Trigger: Nuevo Mensaje de Chat
exports.onNewChatMessage = functions.firestore
    .document("activities/{activityId}/messages/{msgId}")
    // Agregamos tipos explícitos
    .onCreate(async (snap, context) => {
    var _a, _b;
    const msgData = snap.data();
    const activityId = context.params.activityId;
    const activityDoc = await db.collection("activities")
        .doc(activityId)
        .get();
    const hostUid = (_a = activityDoc.data()) === null || _a === void 0 ? void 0 : _a.hostUid;
    const title = (_b = activityDoc.data()) === null || _b === void 0 ? void 0 : _b.title;
    // Si no soy el dueño y escribo, le aviso al dueño
    if (msgData.senderUid !== hostUid && hostUid) {
        const body = `${msgData.senderName}: ${msgData.text}`;
        await sendPushNotification(hostUid, `Nuevo mensaje en ${title}`, body, { type: "chat", activityId });
    }
});
//# sourceMappingURL=index.js.map