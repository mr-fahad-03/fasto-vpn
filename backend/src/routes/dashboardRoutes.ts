import { Router } from "express";
import { dashboardStatsController, recentActivityController } from "../controllers/dashboardController";
import { authAdmin } from "../middlewares/authAdmin";
import { validate } from "../middlewares/validate";
import { dashboardRecentQuerySchema } from "../utils/schemas";
import { asyncHandler } from "../utils/asyncHandler";

export const dashboardRoutes = Router();

dashboardRoutes.use("/admin", authAdmin);
dashboardRoutes.get("/admin/dashboard/stats", asyncHandler(dashboardStatsController));
dashboardRoutes.get(
  "/admin/dashboard/recent-activity",
  validate(dashboardRecentQuerySchema, "query"),
  asyncHandler(recentActivityController),
);
