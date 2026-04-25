import { Router } from "express";
import {
  clearSubscriptionOverrideController,
  listSubscriptionsController,
  setSubscriptionOverrideController,
} from "../controllers/subscriptionController";
import { authAdmin } from "../middlewares/authAdmin";
import { validate } from "../middlewares/validate";
import { asyncHandler } from "../utils/asyncHandler";
import { idParamSchema, subscriptionOverrideSchema, subscriptionsListQuerySchema } from "../utils/schemas";

export const subscriptionRoutes = Router();

subscriptionRoutes.use("/admin", authAdmin);
subscriptionRoutes.get(
  "/admin/subscriptions",
  validate(subscriptionsListQuerySchema, "query"),
  asyncHandler(listSubscriptionsController),
);
subscriptionRoutes.patch(
  "/admin/subscriptions/:id/override",
  validate(idParamSchema, "params"),
  validate(subscriptionOverrideSchema),
  asyncHandler(setSubscriptionOverrideController),
);
subscriptionRoutes.delete(
  "/admin/subscriptions/:id/override",
  validate(idParamSchema, "params"),
  asyncHandler(clearSubscriptionOverrideController),
);
