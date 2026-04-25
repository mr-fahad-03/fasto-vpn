import { Router } from "express";
import { getAdminSettingsController, updateAdminSettingsController } from "../controllers/settingsController";
import { authAdmin } from "../middlewares/authAdmin";
import { validate } from "../middlewares/validate";
import { asyncHandler } from "../utils/asyncHandler";
import { adminSettingsSchema } from "../utils/schemas";

export const settingsRoutes = Router();

settingsRoutes.use("/admin", authAdmin);
settingsRoutes.get("/admin/settings", asyncHandler(getAdminSettingsController));
settingsRoutes.put("/admin/settings", validate(adminSettingsSchema), asyncHandler(updateAdminSettingsController));
