import { NextFunction, Request, Response } from "express";
import { verifyFirebaseToken } from "../config/firebase";
import { ApiError } from "../utils/ApiError";
import { buildRevenueCatAppUserId } from "../utils/identity";
import {
  createGuestSession,
  resolveGuestSession,
  resolveOrMergeFirebaseIdentity,
  touchMobileSession,
} from "../services/mobileSessionService";

export async function mobileAuthOptional(req: Request, res: Response, next: NextFunction): Promise<void> {
  const authHeader = req.header("authorization");
  const guestSessionId = req.header("x-guest-session-id");
  const deviceId = req.header("x-device-id") ?? undefined;
  const platform = req.header("x-platform") ?? undefined;

  if (authHeader?.startsWith("Bearer ")) {
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

    const user = resolved.user;
    if (!user.isActive) {
      throw new ApiError(403, "User account is inactive");
    }

    const session = await touchMobileSession({
      userId: user._id.toString(),
      type: "mobile",
      firebaseUid: decoded.uid,
      deviceId,
      platform,
      ip: req.ip,
      userAgent: req.header("user-agent") ?? undefined,
    });

    res.setHeader("x-device-session-id", session.sessionId);
    if (resolved.mergedGuestUserId) {
      res.setHeader("x-merged-guest-user-id", resolved.mergedGuestUserId);
    }

    req.mobileAuth = {
      userId: user._id.toString(),
      mode: "mobile",
      firebaseUid: decoded.uid,
      rcAppUserId: buildRevenueCatAppUserId(user._id.toString()),
    };

    return next();
  }

  if (guestSessionId) {
    const resolved = await resolveGuestSession(guestSessionId);
    if (resolved) {
      if (!resolved.user.isActive) {
        throw new ApiError(403, "User account is inactive");
      }

      req.mobileAuth = {
        userId: resolved.user._id.toString(),
        mode: "guest",
        guestSessionId,
        rcAppUserId: buildRevenueCatAppUserId(resolved.user._id.toString()),
      };
      return next();
    }
  }

  const guest = await createGuestSession({
    deviceId,
    platform,
    ip: req.ip,
    userAgent: req.header("user-agent") ?? undefined,
  });

  res.setHeader("x-guest-session-id", guest.session.sessionId);
  req.mobileAuth = {
    userId: guest.user._id.toString(),
    mode: "guest",
    guestSessionId: guest.session.sessionId,
    rcAppUserId: buildRevenueCatAppUserId(guest.user._id.toString()),
  };
  next();
}

export async function requireMobileAuth(req: Request, res: Response, next: NextFunction): Promise<void> {
  await mobileAuthOptional(req, res, () => undefined);
  if (!req.mobileAuth) {
    throw new ApiError(401, "Unauthorized mobile request");
  }
  next();
}
