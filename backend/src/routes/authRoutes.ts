import { Router } from "express";
import {
  adminLoginController,
  adminLogoutController,
  adminRefreshController,
} from "../controllers/authController";
import { asyncHandler } from "../utils/asyncHandler";
import { validate } from "../middlewares/validate";
import { adminLoginSchema, adminRefreshSchema } from "../utils/schemas";

export const authRoutes = Router();

authRoutes.post("/admin/auth/login", validate(adminLoginSchema), asyncHandler(adminLoginController));
authRoutes.post("/admin/auth/refresh", validate(adminRefreshSchema), asyncHandler(adminRefreshController));
authRoutes.post("/admin/auth/logout", validate(adminRefreshSchema), asyncHandler(adminLogoutController));
