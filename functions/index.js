const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();
const messaging = getMessaging();

const EVENTS = {
  ORDER_TO_KITCHEN: "order_to_kitchen",
  ORDER_READY: "order_ready",
  BILL_CLEARED: "bill_cleared",
};

/**
 * Caller must be the hotel owner (adminUid) or staff mapped under that owner.
 */
async function assertCallerBelongsToHotel(callerUid, adminUid) {
  if (callerUid === adminUid) return;
  const map = await db.doc(`staffMapping/${callerUid}`).get();
  if (!map.exists || map.data().adminUid !== adminUid) {
    throw new HttpsError(
      "permission-denied",
      "Not allowed to send notifications for this hotel",
    );
  }
}

function messageForEvent(event, tableNumber, billNumber) {
  const table = tableNumber || "Table";
  switch (event) {
    case EVENTS.ORDER_TO_KITCHEN:
      return {
        title: "New kitchen order",
        body: `Order received for ${table}.`,
      };
    case EVENTS.ORDER_READY:
      return {
        title: "Order ready",
        body: `Food is ready to serve — ${table}.`,
      };
    case EVENTS.BILL_CLEARED:
      return {
        title: "Bill & table cleared",
        body: `Bill ${billNumber || ""} — ${table} cleared.`,
      };
    default:
      return { title: "Hotel update", body: `${table}` };
  }
}

function shouldReceiveToken(event, role, department) {
  const r = (role || "").toLowerCase();
  const d = (department || "").toLowerCase();

  if (event === EVENTS.ORDER_TO_KITCHEN) {
    return r === "cook" || d === "kitchen";
  }
  if (event === EVENTS.ORDER_READY) {
    return r === "waiter" || r === "captain" || r === "admin";
  }
  if (event === EVENTS.BILL_CLEARED) {
    return r === "admin" || r === "receptionist";
  }
  return false;
}

exports.sendHotelOrderPush = onCall(
  { region: "us-central1" },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in required");
    }

    const data = request.data || {};
    const adminUid = String(data.adminUid || "").trim();
    const event = String(data.event || "").trim();
    const tableNumber = String(data.tableNumber || "").trim();
    const billNumber = data.billNumber != null ? String(data.billNumber) : "";

    if (!adminUid || !event) {
      throw new HttpsError("invalid-argument", "adminUid and event are required");
    }

    await assertCallerBelongsToHotel(request.auth.uid, adminUid);

    if (!Object.values(EVENTS).includes(event)) {
      throw new HttpsError("invalid-argument", "Unknown event type");
    }

    const tokensSnap = await db
      .collection(`users/${adminUid}/hotelPushTokens`)
      .get();

    const { title, body } = messageForEvent(event, tableNumber, billNumber);
    const tokens = [];
    for (const doc of tokensSnap.docs) {
      const t = doc.data();
      const token = t.fcmToken;
      if (!token || typeof token !== "string") continue;
      if (
        shouldReceiveToken(event, t.role, t.department)
      ) {
        tokens.push(token);
      }
    }

    if (tokens.length === 0) {
      return { sent: 0, skipped: "no_matching_tokens" };
    }

    const response = await messaging.sendEachForMulticast({
      tokens,
      notification: { title, body },
      data: {
        event,
        tableNumber,
        billNumber,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    });

    return {
      sent: response.successCount,
      failed: response.failureCount,
    };
  },
);
