import { Request, Response } from "express";
import { getDashboardStats, getRecentActivity } from "../services/dashboardService";

export async function dashboardStatsController(_req: Request, res: Response): Promise<void> {
  const data = await getDashboardStats();
  res.status(200).json({ success: true, data });
}

export async function recentActivityController(req: Request, res: Response): Promise<void> {
  const limit = Math.min(Math.max(Number(req.query.limit ?? 20), 1), 100);
  const data = await getRecentActivity(limit);
  res.status(200).json({ success: true, data });
}
