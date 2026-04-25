import { Request, Response } from "express";
import { getUserByIdAdmin, listUsersAdmin, updateUserStatusAdmin } from "../services/userAdminService";
import { logActivity } from "../utils/activity";

export async function listUsersController(req: Request, res: Response): Promise<void> {
  const data = await listUsersAdmin(req.query as Record<string, string>);
  res.status(200).json({ success: true, data });
}

export async function updateUserStatusController(req: Request, res: Response): Promise<void> {
  const data = await updateUserStatusAdmin(String(req.params.id), req.body.isActive);

  await logActivity({
    eventType: "admin.user.status",
    metadata: { userId: data.id, isActive: data.isActive, adminId: req.admin?.id },
    ip: req.ip,
    userAgent: req.header("user-agent") ?? undefined,
  });

  res.status(200).json({ success: true, data });
}

export async function getUserByIdController(req: Request, res: Response): Promise<void> {
  const data = await getUserByIdAdmin(String(req.params.id));
  res.status(200).json({ success: true, data });
}
