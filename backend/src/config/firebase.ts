import admin from "firebase-admin";
import { env } from "./env";

let initialized = false;

export function canVerifyFirebase(): boolean {
  return Boolean(env.FIREBASE_PROJECT_ID && env.FIREBASE_CLIENT_EMAIL && env.FIREBASE_PRIVATE_KEY);
}

export function initFirebaseIfNeeded(): void {
  if (initialized || env.FIREBASE_SKIP_VERIFY) {
    return;
  }

  if (!canVerifyFirebase()) {
    return;
  }

  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: env.FIREBASE_PROJECT_ID,
      clientEmail: env.FIREBASE_CLIENT_EMAIL,
      privateKey: env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, "\n"),
    }),
  });

  initialized = true;
}

export async function verifyFirebaseToken(idToken: string): Promise<admin.auth.DecodedIdToken | null> {
  if (env.FIREBASE_SKIP_VERIFY) {
    return {
      uid: idToken,
      aud: "dev",
      auth_time: Date.now(),
      exp: Date.now() + 3600,
      firebase: { sign_in_provider: "custom" },
      iat: Date.now(),
      iss: "dev",
      sub: idToken,
    } as unknown as admin.auth.DecodedIdToken;
  }

  initFirebaseIfNeeded();
  if (!canVerifyFirebase()) {
    return null;
  }

  try {
    return await admin.auth().verifyIdToken(idToken);
  } catch {
    return null;
  }
}
