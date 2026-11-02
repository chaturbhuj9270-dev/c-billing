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
const FREE_TRIAL_DAYS = 30;
const API_VERSION = "2025-01-01";
const PLAY_YEARLY_PRODUCT_ID = "cbilling_yearly";
const PLAY_PACKAGE_NAME = "com.cbilling.app";

/** Server clock + N days → Firestore Timestamp (authoritative expiry). */
function expiryTimestampFrom(baseMs, days) {
  return admin.firestore.Timestamp.fromMillis(
    baseMs + days * 24 * 60 * 60 * 1000
  );
}

function toDate(value) {
  if (!value) return null;
  if (value.toDate) return value.toDate();
  if (value instanceof Date) return value;
  if (typeof value === "string") {
    const d = new Date(value);
    return Number.isNaN(d.getTime()) ? null : d;
  }
  return null;
}

/**
 * Resolve access from user doc using **server time**.
 * Prefers stored subscriptionExpiresAt / trialExpiresAt (written only by Functions).
 */
async function resolveSubscriptionAccess(uid, userRef, data) {
  const serverNowMs = Date.now();
  const serverNow = new Date(serverNowMs);
  const patch = {};

  const subDate = toDate(data.subscriptionDate);
  let paidExpires = toDate(data.subscriptionExpiresAt);
  if (subDate && !paidExpires) {
    paidExpires = new Date(subDate.getTime() + SUBSCRIPTION_DAYS * 86400000);
    patch.subscriptionExpiresAt = admin.firestore.Timestamp.fromDate(paidExpires);
  }

  if (paidExpires) {
    if (Object.keys(patch).length) {
      await userRef.set(patch, { merge: true });
    }
    const allowed = serverNowMs < paidExpires.getTime();
    return {
      allowed,
      status: allowed ? "active" : "expired",
      source: "paid",
      expiresAt: paidExpires.toISOString(),
      serverNow: serverNow.toISOString(),
      remainingDays: allowed
        ? Math.ceil((paidExpires.getTime() - serverNowMs) / 86400000)
        : 0,
    };
  }

  // Free trial — server writes trialExpiresAt once so clients cannot extend it.
  let trialStart =
    toDate(data.trialStartedAt) || toDate(data.createdAt) || null;
  let trialExpires = toDate(data.trialExpiresAt);

  if (!trialStart && !trialExpires) {
    trialStart = serverNow;
    patch.trialStartedAt = admin.firestore.FieldValue.serverTimestamp();
    patch.subscriptionStatus = "trial";
    trialExpires = new Date(serverNowMs + FREE_TRIAL_DAYS * 86400000);
    patch.trialExpiresAt = admin.firestore.Timestamp.fromDate(trialExpires);
  } else if (trialStart && !trialExpires) {
    trialExpires = new Date(
      trialStart.getTime() + FREE_TRIAL_DAYS * 86400000
    );
    patch.trialExpiresAt = admin.firestore.Timestamp.fromDate(trialExpires);
    if (!data.subscriptionStatus) patch.subscriptionStatus = "trial";
  }

  if (Object.keys(patch).length) {
    await userRef.set(patch, { merge: true });
  }

  if (!trialExpires) {
    return {
      allowed: false,
      status: "none",
      source: "none",
      expiresAt: null,
      serverNow: serverNow.toISOString(),
      remainingDays: 0,
    };
  }

  const allowed = serverNowMs < trialExpires.getTime();
  return {
    allowed,
    status: allowed ? "trial" : "expired",
    source: "trial",
    expiresAt: trialExpires.toISOString(),
    serverNow: serverNow.toISOString(),
    remainingDays: allowed
      ? Math.ceil((trialExpires.getTime() - serverNowMs) / 86400000)
      : 0,
  };
}

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
  // Expiry is computed on the server clock — clients never decide the end date.
  const subscriptionExpiresAt = expiryTimestampFrom(Date.now(), SUBSCRIPTION_DAYS);
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
        expiresAt: subscriptionExpiresAt,
      },
      { merge: true }
    );

    tx.set(
      userRef,
      {
        subscriptionDate: now,
        subscriptionExpiresAt,
        lastSubscriptionUpdate: now,
        lastSubscriptionOrderId: orderId,
        subscriptionStatus: "active",
        subscriptionProvider: provider,
      },
      { merge: true }
    );
  });

  return subscriptionExpiresAt.toDate().toISOString();
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

    const expiresAt = await activateSubscription(uid, orderId, {
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
      expiresAt,
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
        checkout_context: "C-Billing Premium - 1 Year",
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
 * Callable: server-authoritative subscription / trial check.
 * Returns expiresAt from Cloud Functions clock — clients must not invent this date.
 *
 * Response:
 *   { allowed, status, source, expiresAt, serverNow, remainingDays }
 */
exports.getSubscriptionAccess = onCall(
  { region: "asia-south1" },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Login required.");
    }

    // Shop owners: own uid. Employees: tenant owner carries the subscription.
    const ownerId =
      (typeof request.auth.token?.tenantOwnerId === "string" &&
        request.auth.token.tenantOwnerId) ||
      request.auth.uid;

    const userRef = db.collection("users").doc(ownerId);
    const snap = await userRef.get();
    if (!snap.exists) {
      // Brand-new account — start trial from server now.
      const trialExpiresAt = expiryTimestampFrom(Date.now(), FREE_TRIAL_DAYS);
      await userRef.set(
        {
          trialStartedAt: admin.firestore.FieldValue.serverTimestamp(),
          trialExpiresAt,
          subscriptionStatus: "trial",
          subscriptionDate: null,
        },
        { merge: true }
      );
      return {
        allowed: true,
        status: "trial",
        source: "trial",
        expiresAt: trialExpiresAt.toDate().toISOString(),
        serverNow: new Date().toISOString(),
        remainingDays: FREE_TRIAL_DAYS,
      };
    }

    return resolveSubscriptionAccess(ownerId, userRef, snap.data() || {});
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
      const expiresAt = await activateSubscription(uid, orderId, order);
      return {
        success: true,
        status: "PAID",
        orderId,
        expiresAt,
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

// ─── Employee management ───────────────────────────────────────────────────

function sanitizeModules(raw) {
  const allow = new Set([
    "dashboard",
    "customers",
    "billing",
    "availability",
    "purchase",
    "invoices",
    "products",
    "suppliers",
    "companies",
    "purchase_return",
    "events",
    "quotations",
    "barcode",
    "expenses",
    "password",
  ]);
  const list = Array.isArray(raw)
    ? raw.map(String).filter((k) => allow.has(k))
    : [];
  // Password always allowed; dashboard/expenses stay opt-in from admin.
  if (!list.includes("password")) list.push("password");
  return [...new Set(list)].sort();
}

async function assertOwner(uid) {
  const snap = await db.collection("users").doc(uid).get();
  if (!snap.exists) {
    throw new HttpsError("failed-precondition", "Owner profile not found");
  }
  const data = snap.data() || {};
  if (data.role === "employee") {
    throw new HttpsError("permission-denied", "Only shop admin can manage employees");
  }
  return data;
}

async function nextEmployeeToken(ownerId) {
  const snap = await db
    .collection("users")
    .doc(ownerId)
    .collection("employees")
    .orderBy("tokenNumber", "desc")
    .limit(1)
    .get();
  if (snap.empty) return 1;
  const max = Number(snap.docs[0].data()?.tokenNumber || 0);
  return Number.isFinite(max) ? max + 1 : 1;
}

exports.createEmployee = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Sign in required");
  }
  const ownerId = request.auth.uid;
  await assertOwner(ownerId);

  const email = String(request.data?.email || "").trim().toLowerCase();
  const password = String(request.data?.password || "");
  const displayName = String(request.data?.displayName || "").trim();
  const phone = request.data?.phone ? String(request.data.phone).trim() : null;
  const counterAccess =
    typeof request.data?.counterAccess === "boolean"
      ? request.data.counterAccess
      : true;
  let modules = sanitizeModules(request.data?.allowedModules);
  if (!counterAccess) {
    modules = modules.filter((m) => m !== "billing");
  }
  const tokenNumber =
    Number(request.data?.tokenNumber) > 0
      ? Number(request.data.tokenNumber)
      : await nextEmployeeToken(ownerId);
  const profile = {
    dateOfBirth: request.data?.dateOfBirth
      ? String(request.data.dateOfBirth)
      : null,
    address: request.data?.address ? String(request.data.address).trim() : null,
    pinCode: request.data?.pinCode ? String(request.data.pinCode).trim() : null,
    govIdNumber: request.data?.govIdNumber
      ? String(request.data.govIdNumber).trim()
      : null,
    govIdType: request.data?.govIdType
      ? String(request.data.govIdType).trim()
      : null,
    salary:
      request.data?.salary != null && Number.isFinite(Number(request.data.salary))
        ? Number(request.data.salary)
        : null,
    dateOfJoining: request.data?.dateOfJoining
      ? String(request.data.dateOfJoining)
      : null,
  };

  if (!email || !email.includes("@")) {
    throw new HttpsError("invalid-argument", "Valid email required");
  }
  if (password.length < 6) {
    throw new HttpsError("invalid-argument", "Password must be at least 6 characters");
  }
  if (!displayName) {
    throw new HttpsError("invalid-argument", "Display name required");
  }

  let userRecord;
  try {
    userRecord = await admin.auth().createUser({
      email,
      password,
      displayName,
      emailVerified: false,
      disabled: false,
    });
  } catch (err) {
    console.error("createEmployee auth error", err);
    throw new HttpsError("already-exists", err.message || "Could not create user");
  }

  const uid = userRecord.uid;
  const now = admin.firestore.FieldValue.serverTimestamp();
  const employeePayload = {
    id: uid,
    email,
    displayName,
    phone,
    tokenNumber,
    counterAccess,
    points: 0,
    ...profile,
    allowedModules: modules,
    active: true,
    createdAt: now,
    updatedAt: now,
  };

  await db.collection("users").doc(ownerId).collection("employees").doc(uid).set(employeePayload);
  await db.collection("users").doc(uid).set(
    {
      email,
      displayName,
      phone,
      tokenNumber,
      counterAccess,
      points: 0,
      ...profile,
      allowedModules: modules,
      active: true,
      role: "employee",
      tenantOwnerId: ownerId,
      createdAt: now,
      updatedAt: now,
    },
    { merge: true }
  );

  await admin.auth().setCustomUserClaims(uid, {
    role: "employee",
    tenantOwnerId: ownerId,
    modules,
    tokenNumber,
    counterAccess,
  });

  return { uid, email, displayName, tokenNumber, counterAccess, allowedModules: modules };
});

exports.updateEmployee = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Sign in required");
  }
  const ownerId = request.auth.uid;
  await assertOwner(ownerId);

  const employeeUid = String(request.data?.employeeUid || "");
  if (!employeeUid) {
    throw new HttpsError("invalid-argument", "employeeUid required");
  }

  const empRef = db.collection("users").doc(ownerId).collection("employees").doc(employeeUid);
  const empSnap = await empRef.get();
  if (!empSnap.exists) {
    throw new HttpsError("not-found", "Employee not found");
  }

  const counterAccess =
    typeof request.data?.counterAccess === "boolean"
      ? request.data.counterAccess
      : empSnap.data()?.counterAccess !== false;
  let modules = sanitizeModules(
    request.data?.allowedModules ?? empSnap.data()?.allowedModules
  );
  if (!counterAccess) {
    modules = modules.filter((m) => m !== "billing");
  }
  const active =
    typeof request.data?.active === "boolean"
      ? request.data.active
      : empSnap.data()?.active !== false;
  const displayName =
    request.data?.displayName != null
      ? String(request.data.displayName).trim()
      : empSnap.data()?.displayName;
  const phone =
    request.data?.phone !== undefined
      ? request.data.phone
        ? String(request.data.phone).trim()
        : null
      : empSnap.data()?.phone;
  const tokenNumber =
    Number(request.data?.tokenNumber) > 0
      ? Number(request.data.tokenNumber)
      : Number(empSnap.data()?.tokenNumber || 0);

  const now = admin.firestore.FieldValue.serverTimestamp();
  const patch = {
    displayName,
    phone,
    tokenNumber,
    counterAccess,
    allowedModules: modules,
    active,
    dateOfBirth:
      request.data?.dateOfBirth !== undefined
        ? request.data.dateOfBirth
          ? String(request.data.dateOfBirth)
          : null
        : empSnap.data()?.dateOfBirth ?? null,
    address:
      request.data?.address !== undefined
        ? request.data.address
          ? String(request.data.address).trim()
          : null
        : empSnap.data()?.address ?? null,
    pinCode:
      request.data?.pinCode !== undefined
        ? request.data.pinCode
          ? String(request.data.pinCode).trim()
          : null
        : empSnap.data()?.pinCode ?? null,
    govIdNumber:
      request.data?.govIdNumber !== undefined
        ? request.data.govIdNumber
          ? String(request.data.govIdNumber).trim()
          : null
        : empSnap.data()?.govIdNumber ?? null,
    govIdType:
      request.data?.govIdType !== undefined
        ? request.data.govIdType
          ? String(request.data.govIdType).trim()
          : null
        : empSnap.data()?.govIdType ?? null,
    salary:
      request.data?.salary !== undefined
        ? request.data.salary != null && Number.isFinite(Number(request.data.salary))
          ? Number(request.data.salary)
          : null
        : empSnap.data()?.salary ?? null,
    dateOfJoining:
      request.data?.dateOfJoining !== undefined
        ? request.data.dateOfJoining
          ? String(request.data.dateOfJoining)
          : null
        : empSnap.data()?.dateOfJoining ?? null,
    updatedAt: now,
  };

  await empRef.set(patch, { merge: true });
  await db.collection("users").doc(employeeUid).set(
    {
      ...patch,
      role: "employee",
      tenantOwnerId: ownerId,
    },
    { merge: true }
  );

  await admin.auth().setCustomUserClaims(employeeUid, {
    role: "employee",
    tenantOwnerId: ownerId,
    modules,
    tokenNumber,
    counterAccess,
  });
  await admin.auth().updateUser(employeeUid, {
    displayName,
    disabled: !active,
  });

  return { uid: employeeUid, ok: true };
});


// ---------------------------------------------------------------------------
// Two-step verification (email OTP on login)
// Delivery:
 // 1) Always queues to Firestore `mail` (use Firebase "Trigger Email" extension)
 // 2) Optionally sends via SMTP if params are set:
 //      firebase functions:config is not used; set params / .env:
 //      SMTP_USER, SMTP_PASS, SMTP_FROM, SMTP_HOST, SMTP_PORT
// ---------------------------------------------------------------------------

const crypto = require("crypto");
const nodemailer = require("nodemailer");

const SMTP_USER = defineString("SMTP_USER", { default: "" });
const SMTP_PASS = defineString("SMTP_PASS", { default: "" });
const SMTP_FROM = defineString("SMTP_FROM", { default: "" });
const SMTP_HOST = defineString("SMTP_HOST", { default: "smtp.gmail.com" });
const SMTP_PORT = defineString("SMTP_PORT", { default: "465" });

const OTP_TTL_MS = 10 * 60 * 1000;
const OTP_MAX_ATTEMPTS = 5;

function hashOtp(otp) {
  return crypto.createHash("sha256").update(String(otp)).digest("hex");
}

function generateOtp() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

async function sendOtpEmail({ to, otp }) {
  const subject = "C-Billing login verification code";
  const text =
    `Your C-Billing login code is ${otp}. It expires in 10 minutes. ` +
    "If you did not try to sign in, ignore this email.";
  const html =
    `<p>Your C-Billing login code is:</p>` +
    `<p style="font-size:28px;font-weight:700;letter-spacing:4px;">${otp}</p>` +
    `<p>It expires in 10 minutes.</p>` +
    `<p>If you did not try to sign in, ignore this email.</p>`;

  // Queue for Firebase "Trigger Email from Firestore" extension.
  await db.collection("mail").add({
    to: [to],
    message: { subject, text, html },
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  const user = String(SMTP_USER.value() || "").trim();
  const pass = String(SMTP_PASS.value() || "").trim();
  const from = String(SMTP_FROM.value() || user).trim();
  if (!user || !pass) {
    return { queued: true, smtp: false };
  }

  const port = Number(SMTP_PORT.value() || 465);
  const transporter = nodemailer.createTransport({
    host: SMTP_HOST.value() || "smtp.gmail.com",
    port,
    secure: port === 465,
    auth: { user, pass },
  });

  await transporter.sendMail({
    from: from || user,
    to,
    subject,
    text,
    html,
  });

  return { queued: true, smtp: true };
}

exports.sendLoginOtp = onCall({ region: "asia-south1" }, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Sign in required");
  }

  const uid = request.auth.uid;
  const force = request.data?.force === true;
  const userRef = db.collection("users").doc(uid);
  const snap = await userRef.get();
  const enabled = snap.data()?.twoStepVerificationEnabled === true;

  if (!force && !enabled) {
    throw new HttpsError(
      "failed-precondition",
      "Two-step verification is not enabled"
    );
  }

  const authUser = await admin.auth().getUser(uid);
  const email = authUser.email;
  if (!email) {
    throw new HttpsError("failed-precondition", "No email on this account");
  }

  const otp = generateOtp();
  const expiresAt = admin.firestore.Timestamp.fromMillis(Date.now() + OTP_TTL_MS);

  await userRef.collection("security").doc("loginOtp").set({
    hash: hashOtp(otp),
    expiresAt,
    attempts: 0,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  try {
    const result = await sendOtpEmail({ to: email, otp });
    return {
      ok: true,
      email,
      expiresInSeconds: Math.floor(OTP_TTL_MS / 1000),
      delivery: result,
    };
  } catch (e) {
    console.error("sendLoginOtp email failed", e);
    throw new HttpsError(
      "internal",
      "Failed to send verification email. Install the Trigger Email extension or set SMTP_USER/SMTP_PASS."
    );
  }
});

exports.verifyLoginOtp = onCall({ region: "asia-south1" }, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Sign in required");
  }

  const uid = request.auth.uid;
  const otp = String(request.data?.otp || "").trim();
  if (!/^\d{6}$/.test(otp)) {
    throw new HttpsError("invalid-argument", "Enter the 6-digit code");
  }

  const otpRef = db
    .collection("users")
    .doc(uid)
    .collection("security")
    .doc("loginOtp");

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(otpRef);
    if (!snap.exists) {
      throw new HttpsError(
        "failed-precondition",
        "No code pending. Request a new one."
      );
    }

    const data = snap.data() || {};
    const attempts = Number(data.attempts || 0);
    if (attempts >= OTP_MAX_ATTEMPTS) {
      tx.delete(otpRef);
      throw new HttpsError(
        "resource-exhausted",
        "Too many attempts. Request a new code."
      );
    }

    const expiresAt = data.expiresAt?.toMillis?.() ?? 0;
    if (!expiresAt || Date.now() > expiresAt) {
      tx.delete(otpRef);
      throw new HttpsError(
        "deadline-exceeded",
        "Code expired. Request a new one."
      );
    }

    if (hashOtp(otp) !== data.hash) {
      tx.update(otpRef, { attempts: attempts + 1 });
      throw new HttpsError("permission-denied", "Invalid code");
    }

    tx.delete(otpRef);
  });

  return { ok: true };
});

exports.setTwoStepVerification = onCall(
  { region: "asia-south1" },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in required");
    }

    const uid = request.auth.uid;
    const enabled = request.data?.enabled === true;
    const otp = String(request.data?.otp || "").trim();

    if (enabled) {
      if (!/^\d{6}$/.test(otp)) {
        throw new HttpsError(
          "invalid-argument",
          "Verify with the 6-digit email code first"
        );
      }

      const otpRef = db
        .collection("users")
        .doc(uid)
        .collection("security")
        .doc("loginOtp");
      const snap = await otpRef.get();
      if (!snap.exists) {
        throw new HttpsError(
          "failed-precondition",
          "Request a verification code first"
        );
      }
      const data = snap.data() || {};
      const expiresAt = data.expiresAt?.toMillis?.() ?? 0;
      if (!expiresAt || Date.now() > expiresAt) {
        await otpRef.delete();
        throw new HttpsError("deadline-exceeded", "Code expired");
      }
      if (hashOtp(otp) !== data.hash) {
        throw new HttpsError("permission-denied", "Invalid code");
      }
      await otpRef.delete();
    }

    await db.collection("users").doc(uid).set(
      {
        twoStepVerificationEnabled: enabled,
        twoStepVerificationUpdatedAt:
          admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return { ok: true, enabled };
  }
);

// ─── Account deletion (Play Store web + in-app) ─────────────────────────────
//
// Play requires:
//   1) In-app delete (Profile → Delete account)
//   2) Public web URL where users can request / complete deletion
//
// Deploy hosting pages + these callables, then paste accountDeletionUrl in
 // Play Console → App content → Data safety / Account deletion.

const DELETION_CONFIRMATION = "DELETE";
const DELETION_OTP_TTL_MS = 15 * 60 * 1000;
const DELETION_OTP_MAX_ATTEMPTS = 5;

function normalizeEmail(raw) {
  return String(raw || "")
    .trim()
    .toLowerCase();
}

async function listEmployeeUidsForOwner(ownerId) {
  const snap = await db
    .collection("users")
    .doc(ownerId)
    .collection("employees")
    .get();
  return snap.docs.map((d) => d.id);
}

/**
 * Deletes Auth user + Firestore profile tree we control for this uid.
 * Employee accounts owned by this shop are disabled and marked deleted.
 */
async function deleteAccountForUid(uid, { source, requestedByEmail } = {}) {
  const userRef = db.collection("users").doc(uid);
  const snap = await userRef.get();
  const profile = snap.exists ? snap.data() || {} : {};
  const role = profile.role || "owner";
  const email =
    requestedByEmail ||
    profile.email ||
    (await admin
      .auth()
      .getUser(uid)
      .then((u) => u.email || null)
      .catch(() => null));

  await db.collection("account_deletion_logs").add({
    uid,
    email: email || null,
    role,
    source: source || "unknown",
    status: "started",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Disable / mark employee accounts belonging to this shop owner.
  if (role !== "employee") {
    try {
      const employeeUids = await listEmployeeUidsForOwner(uid);
      for (const employeeUid of employeeUids) {
        try {
          await admin.auth().updateUser(employeeUid, { disabled: true });
        } catch (e) {
          console.warn("disable employee auth failed", employeeUid, e.message);
        }
        try {
          await db.collection("users").doc(employeeUid).set(
            {
              active: false,
              deletedAt: admin.firestore.FieldValue.serverTimestamp(),
              deletionReason: "owner_account_deleted",
            },
            { merge: true }
          );
        } catch (e) {
          console.warn("mark employee profile failed", employeeUid, e.message);
        }
      }
    } catch (e) {
      console.warn("list employees failed", e.message);
    }
  }

  // Remove owner employee index entries when an employee deletes themselves.
  if (role === "employee" && typeof profile.tenantOwnerId === "string") {
    try {
      await db
        .collection("users")
        .doc(profile.tenantOwnerId)
        .collection("employees")
        .doc(uid)
        .delete();
    } catch (e) {
      console.warn("employee index delete failed", e.message);
    }
  }

  // Wipe cloud profile + subcollections under users/{uid}.
  try {
    if (typeof db.recursiveDelete === "function") {
      await db.recursiveDelete(userRef);
    } else {
      await userRef.set(
        {
          deletedAt: admin.firestore.FieldValue.serverTimestamp(),
          deletionRequested: true,
          email: email || null,
        },
        { merge: true }
      );
      await userRef.delete();
    }
  } catch (e) {
    console.error("Firestore recursive delete failed; falling back", e);
    try {
      await userRef.set(
        {
          deletedAt: admin.firestore.FieldValue.serverTimestamp(),
          deletionRequested: true,
          email: email || null,
        },
        { merge: true }
      );
      await userRef.delete();
    } catch (inner) {
      console.error("Firestore profile delete failed", inner);
    }
  }

  try {
    await admin.auth().deleteUser(uid);
  } catch (e) {
    // Already gone is fine (idempotent).
    if (e?.code !== "auth/user-not-found") {
      console.error("Auth deleteUser failed", e);
      throw new HttpsError(
        "internal",
        e.message || "Failed to delete authentication account"
      );
    }
  }

  await db.collection("account_deletion_logs").add({
    uid,
    email: email || null,
    role,
    source: source || "unknown",
    status: "completed",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { ok: true, uid, email: email || null };
}

async function sendDeletionOtpEmail({ to, otp }) {
  const subject = "C-Billing account deletion code";
  const text =
    `Your C-Billing account deletion code is ${otp}. It expires in 15 minutes. ` +
    "If you did not request account deletion, ignore this email and secure your account.";
  const html =
    `<p>You requested deletion of your <strong>C-Billing</strong> account.</p>` +
    `<p>Your confirmation code is:</p>` +
    `<p style="font-size:28px;font-weight:700;letter-spacing:4px;">${otp}</p>` +
    `<p>It expires in 15 minutes.</p>` +
    `<p>If you did not request this, ignore this email.</p>`;

  await db.collection("mail").add({
    to: [to],
    message: { subject, text, html },
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  const user = String(SMTP_USER.value() || "").trim();
  const pass = String(SMTP_PASS.value() || "").trim();
  const from = String(SMTP_FROM.value() || user).trim();
  if (!user || !pass) {
    return { queued: true, smtp: false };
  }

  const port = Number(SMTP_PORT.value() || 465);
  const transporter = nodemailer.createTransport({
    host: SMTP_HOST.value() || "smtp.gmail.com",
    port,
    secure: port === 465,
    auth: { user, pass },
  });

  await transporter.sendMail({
    from: from || user,
    to,
    subject,
    text,
    html,
  });

  return { queued: true, smtp: true };
}

/**
 * In-app + signed-in web: delete the currently authenticated account.
 * Body: { confirmation: "DELETE" }
 */
exports.deleteMyAccount = onCall({ region: "asia-south1" }, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Sign in required to delete your account.");
  }

  const confirmation = String(request.data?.confirmation || "").trim();
  if (confirmation !== DELETION_CONFIRMATION) {
    throw new HttpsError(
      "invalid-argument",
      `Type ${DELETION_CONFIRMATION} to confirm account deletion.`
    );
  }

  const source = String(request.data?.source || "app");
  return deleteAccountForUid(request.auth.uid, {
    source,
    requestedByEmail: request.auth.token?.email || null,
  });
});

/**
 * Web (unsigned): email a one-time code to the account email.
 * Always returns ok to avoid email enumeration.
 */
exports.requestAccountDeletionOtp = onCall(
  { region: "asia-south1" },
  async (request) => {
    const email = normalizeEmail(request.data?.email);
    if (!email || !email.includes("@")) {
      throw new HttpsError("invalid-argument", "Valid email required");
    }

    let userRecord;
    try {
      userRecord = await admin.auth().getUserByEmail(email);
    } catch (_) {
      return {
        ok: true,
        message:
          "If an account exists for that email, a deletion code was sent.",
      };
    }

    const otp = generateOtp();
    const expiresAt = admin.firestore.Timestamp.fromMillis(
      Date.now() + DELETION_OTP_TTL_MS
    );

    await db.collection("account_deletion_otps").doc(userRecord.uid).set({
      email,
      hash: hashOtp(otp),
      expiresAt,
      attempts: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    try {
      await sendDeletionOtpEmail({ to: email, otp });
    } catch (e) {
      console.error("requestAccountDeletionOtp email failed", e);
      throw new HttpsError(
        "internal",
        "Could not send deletion email. Try again or email support@cbilling.app."
      );
    }

    return {
      ok: true,
      message:
        "If an account exists for that email, a deletion code was sent.",
      expiresInSeconds: Math.floor(DELETION_OTP_TTL_MS / 1000),
    };
  }
);

/**
 * Web: confirm email OTP and permanently delete the account.
 * Body: { email, otp }
 */
exports.confirmAccountDeletionWithOtp = onCall(
  { region: "asia-south1" },
  async (request) => {
    const email = normalizeEmail(request.data?.email);
    const otp = String(request.data?.otp || "").trim();
    if (!email || !email.includes("@")) {
      throw new HttpsError("invalid-argument", "Valid email required");
    }
    if (!/^\d{6}$/.test(otp)) {
      throw new HttpsError("invalid-argument", "Enter the 6-digit code");
    }

    let userRecord;
    try {
      userRecord = await admin.auth().getUserByEmail(email);
    } catch (_) {
      throw new HttpsError(
        "not-found",
        "No account found for that email, or the code is invalid."
      );
    }

    const otpRef = db.collection("account_deletion_otps").doc(userRecord.uid);

    await db.runTransaction(async (tx) => {
      const snap = await tx.get(otpRef);
      if (!snap.exists) {
        throw new HttpsError(
          "failed-precondition",
          "No deletion code pending. Request a new one."
        );
      }
      const data = snap.data() || {};
      if (normalizeEmail(data.email) !== email) {
        throw new HttpsError("permission-denied", "Email does not match code.");
      }
      const attempts = Number(data.attempts || 0);
      if (attempts >= DELETION_OTP_MAX_ATTEMPTS) {
        tx.delete(otpRef);
        throw new HttpsError(
          "resource-exhausted",
          "Too many attempts. Request a new code."
        );
      }
      const expiresAt = data.expiresAt?.toMillis?.() ?? 0;
      if (!expiresAt || Date.now() > expiresAt) {
        tx.delete(otpRef);
        throw new HttpsError(
          "deadline-exceeded",
          "Code expired. Request a new one."
        );
      }
      if (hashOtp(otp) !== data.hash) {
        tx.update(otpRef, { attempts: attempts + 1 });
        throw new HttpsError("permission-denied", "Invalid code");
      }
      tx.delete(otpRef);
    });

    return deleteAccountForUid(userRecord.uid, {
      source: "web_otp",
      requestedByEmail: email,
    });
  }
);
)