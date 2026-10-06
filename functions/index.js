/**
 * Subscription payment Cloud Functions (Google Play Billing + optional Cashfree).
 *
 * Play Billing secrets:
 *   firebase functions:secrets:set GOOGLE_PLAY_SERVICE_ACCOUNT_JSON
 *   (Paste the full Play Console linked service-account JSON)
 *
 * Optional Cashfree secrets:
 *   firebase functions:secrets:set CASHFREE_APP_ID
 *   firebase functions:secrets:set CASHFREE_SECRET_KEY
 *
 * Deploy:
 *   firebase deploy --only functions,firestore:rules
 */

const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret, defineString } = require("firebase-functions/params");
const { google } = require("googleapis");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

const CASHFREE_APP_ID = defineSecret("CASHFREE_APP_ID");
const CASHFREE_SECRET_KEY = defineSecret("CASHFREE_SECRET_KEY");
const CASHFREE_ENV = defineString("CASHFREE_ENV", { default: "SANDBOX" });
const GOOGLE_PLAY_SERVICE_ACCOUNT_JSON = defineSecret(
  "GOOGLE_PLAY_SERVICE_ACCOUNT_JSON"
);

const SUBSCRIPTION_AMOUNT = 3999;
const SUBSCRIPTION_CURRENCY = "INR";
const SUBSCRIPTION_DAYS = 365;
const API_VERSION = "2025-01-01";
const PLAY_YEARLY_PRODUCT_ID = "cbilling_yearly";
const PLAY_PACKAGE_NAME = "com.example.c_billing";

function cashfreeBaseUrl(envValue) {
  return String(envValue || "SANDBOX").toUpperCase() === "PRODUCTION"
    ? "https://api.cashfree.com/pg"
    : "https://sandbox.cashfree.com/pg";
}

function cashfreeHeaders() {
  return {
    accept: "application/json",
    "content-type": "application/json",
    "x-api-version": API_VERSION,
    "x-client-id": CASHFREE_APP_ID.value(),
    "x-client-secret": CASHFREE_SECRET_KEY.value(),
  };
}

function buildOrderId(uid) {
  const shortUid = String(uid).replace(/[^a-zA-Z0-9]/g, "").slice(0, 10);
  const ts = Date.now().toString(36);
  return `sub_${shortUid}_${ts}`.slice(0, 45);
}

function normalizePhone(raw) {
  if (!raw) return "9999999999";
  const digits = String(raw).replace(/\D/g, "");
  if (digits.length >= 10) return digits.slice(-10);
  return "9999999999";
}

async function activateSubscription(uid, orderId, orderData = {}) {
  const now = admin.firestore.FieldValue.serverTimestamp();
  const userRef = db.collection("users").doc(uid);
  const paymentRef = userRef.collection("subscription_payments").doc(orderId);
  const provider = orderData.provider || "cashfree";

  await db.runTransaction(async (tx) => {
    const paymentSnap = await tx.get(paymentRef);
    if (paymentSnap.exists && paymentSnap.data()?.status === "PAID") {
      return; // already activated
    }

    tx.set(
      paymentRef,
      {
        orderId,
        amount: SUBSCRIPTION_AMOUNT,
        currency: SUBSCRIPTION_CURRENCY,
        status: "PAID",
        provider,
        productId: orderData.productId || PLAY_YEARLY_PRODUCT_ID,
        purchaseToken: orderData.purchaseToken || null,
        cashfreeOrderStatus: orderData.order_status || null,
        paymentSessionId: orderData.payment_session_id || null,
        playSubscriptionState: orderData.playSubscriptionState || null,
        updatedAt: now,
        paidAt: now,
      },
      { merge: true }
    );

    tx.set(
      userRef,
      {
        subscriptionDate: now,
        lastSubscriptionUpdate: now,
        lastSubscriptionOrderId: orderId,
        subscriptionStatus: "active",
        subscriptionProvider: provider,
      },
      { merge: true }
    );
  });
}

function getPlayAuthClient() {
  const raw = GOOGLE_PLAY_SERVICE_ACCOUNT_JSON.value();
  if (!raw) {
    throw new HttpsError(
      "failed-precondition",
      "GOOGLE_PLAY_SERVICE_ACCOUNT_JSON secret is not configured"
    );
  }

  let credentials;
  try {
    credentials = JSON.parse(raw);
  } catch (_) {
    throw new HttpsError(
      "failed-precondition",
      "GOOGLE_PLAY_SERVICE_ACCOUNT_JSON is not valid JSON"
    );
  }

  return new google.auth.GoogleAuth({
    credentials,
    scopes: ["https://www.googleapis.com/auth/androidpublisher"],
  });
}

async function verifyGooglePlayPurchase({
  packageName,
  productId,
  purchaseToken,
}) {
  const auth = getPlayAuthClient();
  const androidpublisher = google.androidpublisher({ version: "v3", auth });

  // Prefer subscriptionsv2 (Play Billing subscriptions).
  try {
    const subRes = await androidpublisher.purchases.subscriptionsv2.get({
      packageName,
      token: purchaseToken,
    });
    const data = subRes.data || {};
    const state = String(data.subscriptionState || "");
    const lineItems = data.lineItems || [];
    const productIds = lineItems
      .map((item) => item.productId)
      .filter(Boolean);

    const productMatches =
      productIds.length === 0 || productIds.includes(productId);
    const active =
      state === "SUBSCRIPTION_STATE_ACTIVE" ||
      state === "SUBSCRIPTION_STATE_IN_GRACE_PERIOD";

    if (!productMatches) {
      throw new HttpsError(
        "failed-precondition",
        `Purchase product mismatch. Expected ${productId}`
      );
    }
    if (!active) {
      throw new HttpsError(
        "failed-precondition",
        `Subscription not active (state: ${state || "unknown"})`
      );
    }

    return {
      kind: "subscription",
      playSubscriptionState: state,
      raw: data,
    };
  } catch (error) {
    // Fallback: one-time / non-subscription managed product.
    if (error instanceof HttpsError) throw error;

    try {
      const productRes = await androidpublisher.purchases.products.get({
        packageName,
        productId,
        token: purchaseToken,
      });
      const data = productRes.data || {};
      const purchaseState = Number(data.purchaseState);
      // 0 = purchased
      if (purchaseState !== 0) {
        throw new HttpsError(
          "failed-precondition",
          `Play product not purchased (state: ${purchaseState})`
        );
      }
      return {
        kind: "product",
        playSubscriptionState: "PURCHASED",
        raw: data,
      };
    } catch (productError) {
      if (productError instanceof HttpsError) throw productError;
      console.error("Play verification failed", error, productError);
      throw new HttpsError(
        "failed-precondition",
        productError?.message ||
          error?.message ||
          "Google Play purchase verification failed"
      );
    }
  }
}

/**
 * Callable: verify Google Play purchase token and activate yearly subscription.
 */
exports.verifyPlayPurchase = onCall(
  {
    secrets: [GOOGLE_PLAY_SERVICE_ACCOUNT_JSON],
    region: "asia-south1",
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Login required.");
    }

    const uid = request.auth.uid;
    const productId = request.data?.productId || PLAY_YEARLY_PRODUCT_ID;
    const purchaseToken = request.data?.purchaseToken;
    const packageName = request.data?.packageName || PLAY_PACKAGE_NAME;
    const source = request.data?.source || "google_play";

    if (!purchaseToken || typeof purchaseToken !== "string") {
      throw new HttpsError("invalid-argument", "purchaseToken is required");
    }
    if (productId !== PLAY_YEARLY_PRODUCT_ID) {
      throw new HttpsError("invalid-argument", "Unsupported productId");
    }

    if (source === "app_store") {
      // iOS StoreKit verification can be added later; activate with token record for now
      // only after App Store server verification is wired.
      throw new HttpsError(
        "unimplemented",
        "App Store purchase verification is not configured yet. Use Google Play on Android."
      );
    }

    const verified = await verifyGooglePlayPurchase({
      packageName,
      productId,
      purchaseToken,
    });

    // Stable doc id from token (Firestore doc ids max ~1500 chars; tokens are shorter).
    const orderId = `play_${purchaseToken.slice(0, 80)}`;

    await activateSubscription(uid, orderId, {
      provider: "google_play",
      productId,
      purchaseToken,
      playSubscriptionState: verified.playSubscriptionState,
    });

    return {
      success: true,
      status: "ACTIVE",
      orderId,
      productId,
      message: "Google Play subscription activated for 1 year",
    };
  }
);

async function fetchCashfreeOrder(orderId) {
  const baseUrl = cashfreeBaseUrl(CASHFREE_ENV.value());
  const response = await fetch(`${baseUrl}/orders/${encodeURIComponent(orderId)}`, {
    method: "GET",
    headers: cashfreeHeaders(),
  });

  const body = await response.json().catch(() => ({}));
  if (!response.ok) {
    const message =
      body?.message || body?.error || `Cashfree order fetch failed (${response.status})`;
    throw new HttpsError("failed-precondition", message);
  }
  return body;
}

/**
 * Callable: create a Cashfree order for ₹3999 yearly subscription.
 * Returns { orderId, paymentSessionId, environment, amount }
 */
exports.createSubscriptionOrder = onCall(
  {
    secrets: [CASHFREE_APP_ID, CASHFREE_SECRET_KEY],
    region: "asia-south1",
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Login required to subscribe.");
    }

    const uid = request.auth.uid;
    const userSnap = await db.collection("users").doc(uid).get();
    const user = userSnap.data() || {};

    const customerName = [user.firstName, user.lastName]
      .filter(Boolean)
      .join(" ")
      .trim() || "C-Billing User";
    const customerEmail = user.email || request.auth.token.email || "user@c-billing.app";
    const customerPhone = normalizePhone(user.contact || request.data?.phone);

    const orderId = buildOrderId(uid);
    const environment =
      String(CASHFREE_ENV.value() || "SANDBOX").toUpperCase() === "PRODUCTION"
        ? "PRODUCTION"
        : "SANDBOX";

    const payload = {
      order_id: orderId,
      order_amount: SUBSCRIPTION_AMOUNT,
      order_currency: SUBSCRIPTION_CURRENCY,
      customer_details: {
        customer_id: uid.slice(0, 50),
        customer_name: customerName.slice(0, 100),
        customer_email: customerEmail,
        customer_phone: customerPhone,
      },
      order_meta: {
        return_url: `https://c-billing.app/subscription/return?order_id={order_id}`,
      },
      order_note: "C-Billing yearly subscription",
      order_tags: {
        uid,
        plan: "yearly",
        checkout_context: "C-Billing Premium — 1 Year",
      },
    };

    const baseUrl = cashfreeBaseUrl(CASHFREE_ENV.value());
    const response = await fetch(`${baseUrl}/orders`, {
      method: "POST",
      headers: cashfreeHeaders(),
      body: JSON.stringify(payload),
    });

    const body = await response.json().catch(() => ({}));
    if (!response.ok) {
      console.error("Cashfree create order failed", response.status, body);
      throw new HttpsError(
        "internal",
        body?.message || body?.error || "Failed to create payment order"
      );
    }

    const paymentSessionId = body.payment_session_id;
    if (!paymentSessionId) {
      throw new HttpsError("internal", "Cashfree did not return payment_session_id");
    }

    await db
      .collection("users")
      .doc(uid)
      .collection("subscription_payments")
      .doc(orderId)
      .set({
        orderId,
        amount: SUBSCRIPTION_AMOUNT,
        currency: SUBSCRIPTION_CURRENCY,
        status: "CREATED",
        paymentSessionId,
        environment,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    return {
      orderId,
      paymentSessionId,
      environment,
      amount: SUBSCRIPTION_AMOUNT,
      currency: SUBSCRIPTION_CURRENCY,
      durationDays: SUBSCRIPTION_DAYS,
    };
  }
);

/**
 * Callable: verify Cashfree order and activate subscription when PAID.
 */
exports.verifySubscriptionPayment = onCall(
  {
    secrets: [CASHFREE_APP_ID, CASHFREE_SECRET_KEY],
    region: "asia-south1",
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Login required.");
    }

    const orderId = request.data?.orderId;
    if (!orderId || typeof orderId !== "string") {
      throw new HttpsError("invalid-argument", "orderId is required");
    }

    const uid = request.auth.uid;
    const paymentRef = db
      .collection("users")
      .doc(uid)
      .collection("subscription_payments")
      .doc(orderId);
    const paymentSnap = await paymentRef.get();

    if (!paymentSnap.exists) {
      throw new HttpsError("not-found", "Payment order not found for this user");
    }

    const order = await fetchCashfreeOrder(orderId);
    const status = String(order.order_status || "").toUpperCase();

    if (status === "PAID") {
      await activateSubscription(uid, orderId, order);
      return {
        success: true,
        status: "PAID",
        orderId,
        message: "Subscription activated for 1 year",
      };
    }

    await paymentRef.set(
      {
        status,
        cashfreeOrderStatus: status,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return {
      success: false,
      status,
      orderId,
      message: `Payment not completed (status: ${status})`,
    };
  }
);

/**
 * HTTP webhook for Cashfree payment notifications (optional but recommended).
 * Configure this URL in Cashfree dashboard:
 *   https://asia-south1-<PROJECT_ID>.cloudfunctions.net/cashfreeWebhook
 */
exports.cashfreeWebhook = onRequest(
  {
    secrets: [CASHFREE_APP_ID, CASHFREE_SECRET_KEY],
    region: "asia-south1",
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    try {
      const payload = req.body || {};
      const orderId =
        payload?.data?.order?.order_id ||
        payload?.order?.order_id ||
        payload?.order_id;
      const orderStatus = String(
        payload?.data?.order?.order_status ||
          payload?.order?.order_status ||
          payload?.order_status ||
          ""
      ).toUpperCase();

      if (!orderId) {
        res.status(400).json({ ok: false, message: "Missing order_id" });
        return;
      }

      // Confirm with Cashfree API (do not trust webhook payload alone)
      const order = await fetchCashfreeOrder(orderId);
      const confirmedStatus = String(order.order_status || "").toUpperCase();

      if (confirmedStatus !== "PAID") {
        res.status(200).json({ ok: true, status: confirmedStatus });
        return;
      }

      const uid = order?.order_tags?.uid;
      if (!uid) {
        // Fallback: look up payment docs
        const paymentsQuery = await db
          .collectionGroup("subscription_payments")
          .where("orderId", "==", orderId)
          .limit(1)
          .get();

        if (paymentsQuery.empty) {
          console.warn("Webhook PAID but no matching payment/user", orderId);
          res.status(200).json({ ok: false, message: "No matching user" });
          return;
        }

        const pathUid = paymentsQuery.docs[0].ref.parent.parent.id;
        await activateSubscription(pathUid, orderId, order);
        res.status(200).json({ ok: true, status: "PAID", orderStatus });
        return;
      }

      await activateSubscription(uid, orderId, order);
      res.status(200).json({ ok: true, status: "PAID" });
    } catch (error) {
      console.error("cashfreeWebhook error", error);
      res.status(500).json({ ok: false, message: "Webhook processing failed" });
    }
  }
);
