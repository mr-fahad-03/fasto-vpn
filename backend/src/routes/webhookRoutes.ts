import { Router } from "express";
import { revenueCatWebhookController } from "../controllers/webhookController";
import { asyncHandler } from "../utils/asyncHandler";
import { validate } from "../middlewares/validate";
import { revenueCatWebhookSchema } from "../utils/schemas";

export const webhookRoutes = Router();

webhookRoutes.post(
  "/webhooks/revenuecat",
  validate(revenueCatWebhookSchema),
  asyncHandler(revenueCatWebhookController),
);
