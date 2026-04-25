import { Request, Response } from "express";
import { verifyFirebaseToken } from "../config/firebase";
import {
  createGuestSession,
  resolveOrMergeFirebaseIdentity,
  touchMobileSession,
} from "../services/mobileSessionService";
import { getPlanForUser } from "../services/subscriptionService";
import { ApiError } from "../utils/ApiError";
import { logActivity } from "../utils/activity";
import { buildRevenueCatAppUserId } from "../utils/identity";

export async function createGuestSessionController(req: Request, res: Response): Promise<void> {
  const guest = await createGuestSession({
    deviceId: req.header("x-device-id") ?? undefined,
    platform: req.header("x-platform") ?? undefined,
    ip: req.ip,
    userAgent: req.header("user-agent") ?? undefined,
  });

  const userId = guest.user._id.toString();
  const entitlement = await getPlanForUser(userId);

  await logActivity({
    userId,
    eventType: "guest.session.create",
    metadata: { sessionId: guest.session.sessionId },
    ip: req.ip,
    userAgent: req.header("user-agent") ?? undefined,
  });

  res.status(201).json({
    success: true,
    data: {
      guestSessionId: guest.session.sessionId,
      userId,
      rcAppUserId: buildRevenueCatAppUserId(userId),
      mode: "guest",
      entitlement,
    },
  });
}

export async function authenticateFirebaseController(req: Request, res: Response): Promise<void> {
  const authHeader = req.header("authorization");
  const guestSessionId = req.header("x-guest-session-id") ?? undefined;

  if (!authHeader?.startsWith("Bearer ")) {
    throw new ApiError(401, "Missing Firebase bearer token");
  }

  const token = authHeader.replace("Bearer ", "").trim();
  const decoded = await verifyFirebaseToken(token);

  if (!decoded) {
    throw new ApiError(401, "Invalid Firebase token");
  }

  const resolved = await resolveOrMergeFirebaseIdentity({
    firebaseUid: decoded.uid,
    email: decoded.email,
    displayName: decoded.name,
    guestSessionId,
  });

  if (!resolved.user.isActive) {
    throw new ApiError(403, "User account is inactive");
  }

  const deviceSession = await touchMobileSession({
    userId: resolved.user._id.toString(),
    type: "mobile",
    firebaseUid: decoded.uid,
    deviceId: req.header("x-device-id") ?? undefined,
    platform: req.header("x-platform") ?? undefined,
    ip: req.ip,
    userAgent: req.header("user-agent") ?? undefined,
  });

  const entitlement = await getPlanForUser(resolved.user._id.toString());

  await logActivity({
    userId: resolved.user._id.toString(),
    eventType: "mobile.auth.firebase",
    metadata: {
      firebaseUid: decoded.uid,
      mergedGuestUserId: resolved.mergedGuestUserId,
      deviceSessionId: deviceSession.sessionId,
    },
    ip: req.ip,
    userAgent: req.header("user-agent") ?? undefined,
  });

  res.status(200).json({
    success: true,
    data: {
      userId: resolved.user._id.toString(),
      rcAppUserId: buildRevenueCatAppUserId(resolved.user._id.toString()),
      mode: "mobile",
      deviceSessionId: deviceSession.sessionId,
      mergedGuestUserId: resolved.mergedGuestUserId,
      entitlement,
    },
  });
}

export async function mobileEntitlementController(req: Request, res: Response): Promise<void> {
  const mobile = req.mobileAuth;

  if (!mobile) {
    res.status(200).json({
      success: true,
      data: {
        plan: "free",
        hasPremium: false,
        adsEnabled: true,
        status: "free",
        userId: null,
        rcAppUserId: null,
        expiresAt: null,
      },
    });
    return;
  }

  const plan = await getPlanForUser(mobile.userId);
  res.status(200).json({ success: true, data: plan });
}
