import { Request, Response } from "express";
import { getAdminSettings, updateAdminSettings } from "../services/settingsService";
import { logActivity } from "../utils/activity";

export async function getAdminSettingsController(_req: Request, res: Response): Promise<void> {
  const data = await getAdminSettings();
  res.status(200).json({ success: true, data });
}

export async function updateAdminSettingsController(req: Request, res: Response): Promise<void> {
  const data = await updateAdminSettings(req.body);

  await logActivity({
    eventType: "admin.settings.update",
    metadata: {
      adminId: req.admin?.id,
    },
    ip: req.ip,
    userAgent: req.header("user-agent") ?? undefined,
  });

  res.status(200).json({ success: true, data });
}
