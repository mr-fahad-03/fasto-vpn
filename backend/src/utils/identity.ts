import { Types } from "mongoose";

const RC_PREFIX = "u_";

export function buildRevenueCatAppUserId(userId: string): string {
  return `${RC_PREFIX}${userId}`;
}

export function parseRevenueCatAppUserId(appUserId: string): {
  userId?: string;
  firebaseUid?: string;
} {
  if (appUserId.startsWith(RC_PREFIX)) {
    const rawId = appUserId.slice(RC_PREFIX.length);
    if (Types.ObjectId.isValid(rawId)) {
      return { userId: rawId };
    }
  }

  return { firebaseUid: appUserId };
}
