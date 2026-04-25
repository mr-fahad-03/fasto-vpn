import { Request, Response } from "express";
import { adminLogin, adminLogout, adminRefresh } from "../services/authService";
import { logActivity } from "../utils/activity";

export async function adminLoginController(req: Request, res: Response): Promise<void> {
  const data = await adminLogin(req.body);

  await logActivity({
    eventType: "admin.login",
    metadata: { adminEmail: data.admin.email },
    ip: req.ip,
    userAgent: req.header("user-agent") ?? undefined,
  });

  res.status(200).json({ success: true, data });
}

export async function adminRefreshController(req: Request, res: Response): Promise<void> {
  const data = await adminRefresh(req.body.refreshToken);
  res.status(200).json({ success: true, data });
}

export async function adminLogoutController(req: Request, res: Response): Promise<void> {
  await adminLogout(req.body.refreshToken);
  res.status(200).json({ success: true });
}
