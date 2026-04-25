import { Request, Response } from "express";
import {
  clearSubscriptionOverride,
  listSubscriptionsAdmin,
  setSubscriptionOverride,
} from "../services/subscriptionAdminService";
import { logActivity } from "../utils/activity";

export async function listSubscriptionsController(req: Request, res: Response): Promise<void> {
  const data = await listSubscriptionsAdmin(req.query as Record<string, string>);
  res.status(200).json({ success: true, data });
}

export async function setSubscriptionOverrideController(req: Request, res: Response): Promise<void> {
  const data = await setSubscriptionOverride({
    subscriptionId: String(req.params.id),
    plan: req.body.plan,
    reason: req.body.reason,
    adminId: req.admin!.id,
  });

  await logActivity({
    eventType: "admin.subscription.override.set",
    metadata: {
      subscriptionId: data.id,
      plan: req.body.plan,
      adminId: req.admin!.id,
    },
    ip: req.ip,
    userAgent: req.header("user-agent") ?? undefined,
  });

  res.status(200).json({ success: true, data });
}

export async function clearSubscriptionOverrideController(req: Request, res: Response): Promise<void> {
  const data = await clearSubscriptionOverride(String(req.params.id));

  await logActivity({
    eventType: "admin.subscription.override.clear",
    metadata: {
      subscriptionId: data.id,
      adminId: req.admin!.id,
    },
    ip: req.ip,
    userAgent: req.header("user-agent") ?? undefined,
  });

  res.status(200).json({ success: true, data });
}
