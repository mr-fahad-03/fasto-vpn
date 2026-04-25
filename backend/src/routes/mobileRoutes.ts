import { Router } from "express";
import {
  authenticateFirebaseController,
  createGuestSessionController,
  mobileEntitlementController,
} from "../controllers/mobileController";
import {
  mobileProxyConnectController,
  mobileProxyListController,
} from "../controllers/proxyController";
import { mobileAuthOptional } from "../middlewares/mobileAuth";
import { resolveEntitlement } from "../middlewares/entitlement";
import { asyncHandler } from "../utils/asyncHandler";
import { validate } from "../middlewares/validate";
import { mobileProxyConnectSchema } from "../utils/schemas";

export const mobileRoutes = Router();

mobileRoutes.post("/mobile/sessions/guest", asyncHandler(createGuestSessionController));
mobileRoutes.post("/mobile/auth/firebase", asyncHandler(authenticateFirebaseController));
mobileRoutes.get("/mobile/proxies", asyncHandler(mobileAuthOptional), asyncHandler(resolveEntitlement), asyncHandler(mobileProxyListController));
mobileRoutes.post(
  "/mobile/proxies/connect",
  validate(mobileProxyConnectSchema),
  asyncHandler(mobileAuthOptional),
  asyncHandler(resolveEntitlement),
  asyncHandler(mobileProxyConnectController),
);
mobileRoutes.get(
  "/mobile/entitlement",
  asyncHandler(mobileAuthOptional),
  asyncHandler(resolveEntitlement),
  asyncHandler(mobileEntitlementController),
);
