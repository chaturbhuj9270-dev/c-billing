import { initializeApp } from "https://www.gstatic.com/firebasejs/11.6.0/firebase-app.js";
import {
  getAuth,
  signInWithEmailAndPassword,
  signOut,
} from "https://www.gstatic.com/firebasejs/11.6.0/firebase-auth.js";
import {
  getFunctions,
  httpsCallable,
} from "https://www.gstatic.com/firebasejs/11.6.0/firebase-functions.js";
import { FUNCTIONS_REGION, firebaseConfig } from "./firebase-app.js";

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const functions = getFunctions(app, FUNCTIONS_REGION);

const deleteMyAccount = httpsCallable(functions, "deleteMyAccount");
const requestAccountDeletionOtp = httpsCallable(
  functions,
  "requestAccountDeletionOtp"
);
const confirmAccountDeletionWithOtp = httpsCallable(
  functions,
  "confirmAccountDeletionWithOtp"
);

const statusEl = document.getElementById("status");
const signInForm = document.getElementById("sign-in-form");
const otpRequestForm = document.getElementById("otp-request-form");
const otpConfirmForm = document.getElementById("otp-confirm-form");

function showStatus(message, ok) {
  statusEl.textContent = message;
  statusEl.className = `status show ${ok ? "ok" : "err"}`;
}

function setBusy(button, busy) {
  if (!button) return;
  button.disabled = busy;
  button.dataset.label ??= button.textContent;
  button.textContent = busy ? "Please wait…" : button.dataset.label;
}

document.querySelectorAll(".tab").forEach((tab) => {
  tab.addEventListener("click", () => {
    document.querySelectorAll(".tab").forEach((t) => t.classList.remove("active"));
    document.querySelectorAll(".panel").forEach((p) => p.classList.remove("active"));
    tab.classList.add("active");
    document.getElementById(tab.dataset.panel)?.classList.add("active");
    statusEl.className = "status";
  });
});

signInForm?.addEventListener("submit", async (event) => {
  event.preventDefault();
  const button = signInForm.querySelector("button[type='submit']");
  const email = signInForm.email.value.trim();
  const password = signInForm.password.value;
  const confirmed = signInForm.confirm.checked;

  if (!confirmed) {
    showStatus("Confirm that you understand deletion is permanent.", false);
    return;
  }

  setBusy(button, true);
  try {
    await signInWithEmailAndPassword(auth, email, password);
    await deleteMyAccount({ confirmation: "DELETE", source: "web_password" });
    try {
      await signOut(auth);
    } catch (_) {
      /* account already gone */
    }
    showStatus(
      "Your C-Billing account has been permanently deleted. You can close this page.",
      true
    );
    signInForm.reset();
  } catch (error) {
    console.error(error);
    showStatus(humanizeError(error), false);
  } finally {
    setBusy(button, false);
  }
});

otpRequestForm?.addEventListener("submit", async (event) => {
  event.preventDefault();
  const button = otpRequestForm.querySelector("button[type='submit']");
  const email = otpRequestForm.email.value.trim();
  setBusy(button, true);
  try {
    const result = await requestAccountDeletionOtp({ email });
    const message =
      result.data?.message ||
      "If an account exists for that email, a deletion code was sent.";
    showStatus(message, true);
    otpConfirmForm.email.value = email;
    otpConfirmForm.hidden = false;
  } catch (error) {
    console.error(error);
    showStatus(humanizeError(error), false);
  } finally {
    setBusy(button, false);
  }
});

otpConfirmForm?.addEventListener("submit", async (event) => {
  event.preventDefault();
  const button = otpConfirmForm.querySelector("button[type='submit']");
  const email = otpConfirmForm.email.value.trim();
  const otp = otpConfirmForm.otp.value.trim();
  const confirmed = otpConfirmForm.confirm.checked;

  if (!confirmed) {
    showStatus("Confirm that you understand deletion is permanent.", false);
    return;
  }

  setBusy(button, true);
  try {
    await confirmAccountDeletionWithOtp({ email, otp });
    showStatus(
      "Your C-Billing account has been permanently deleted. You can close this page.",
      true
    );
    otpRequestForm.reset();
    otpConfirmForm.reset();
    otpConfirmForm.hidden = true;
  } catch (error) {
    console.error(error);
    showStatus(humanizeError(error), false);
  } finally {
    setBusy(button, false);
  }
});

function humanizeError(error) {
  const code = error?.code || error?.details?.code || "";
  const message = error?.message || "Something went wrong.";
  if (String(message).includes("auth/invalid-credential") || code.includes("invalid-credential")) {
    return "Incorrect email or password.";
  }
  if (String(message).includes("auth/too-many-requests")) {
    return "Too many attempts. Wait a moment and try again.";
  }
  if (String(message).includes("auth/network-request-failed")) {
    return "Network error. Check your connection and try again.";
  }
  return message.replace(/^Firebase:\s*/i, "").replace(/\s*\(.*\)\s*$/, "");
}
