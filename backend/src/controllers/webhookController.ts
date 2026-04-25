import crypto from "crypto";
import { Request, Response } from "express";
import { env } from "../config/env";
import { processRevenueCatEvent } from "../services/subscriptionService";
import { ApiError } from "../utils/ApiError";
import { logActivity } from "../utils/activity";

function verifyRevenueCatSignature(rawBody: string, signature?: string): boolean {
  if (!signature) return false;

  const digest = crypto.createHmac("sha256", env.REVENUECAT_WEBHOOK_SECRET).update(rawBody).digest("hex");
  return digest === signature;
}

export async function revenueCatWebhookController(req: Request, res: Response): Promise<void> {
  const signature = req.header("x-revenuecat-signature") ?? undefined;
  const verified = verifyRevenueCatSignature(req.rawBody ?? "", signature);

  if (!verified) {
    throw new ApiError(401, "Invalid RevenueCat signature");
  }

  await processRevenueCatEvent(req.body);

  await logActivity({
    eventType: "revenuecat.webhook",
    metadata: {
      type: req.body.event?.type,
      appUserId: req.body.event?.app_user_id,
    },
    ip: req.ip,
    userAgent: req.header("user-agent") ?? undefined,
  });

  res.status(200).json({ success: true });
}
