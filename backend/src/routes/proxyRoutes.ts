import { Router } from "express";
import {
  bulkImportProxiesController,
  createProxyController,
  deleteProxyController,
  getProxyByIdController,
  listAdminProxiesController,
  reorderProxiesController,
  updateProxyController,
  updateProxyStatusController,
} from "../controllers/proxyController";
import { authAdmin } from "../middlewares/authAdmin";
import { validate } from "../middlewares/validate";
import { asyncHandler } from "../utils/asyncHandler";
import {
  bulkImportSchema,
  createProxySchema,
  idParamSchema,
  proxyListQuerySchema,
  reorderProxiesSchema,
  updateProxySchema,
  updateProxyStatusSchema,
} from "../utils/schemas";

export const proxyRoutes = Router();

proxyRoutes.use("/admin", authAdmin);
proxyRoutes.get("/admin/proxies", validate(proxyListQuerySchema, "query"), asyncHandler(listAdminProxiesController));
proxyRoutes.post("/admin/proxies", validate(createProxySchema), asyncHandler(createProxyController));
proxyRoutes.post(
  "/admin/proxies/bulk-import",
  validate(bulkImportSchema),
  asyncHandler(bulkImportProxiesController),
);
proxyRoutes.post("/admin/proxies/reorder", validate(reorderProxiesSchema), asyncHandler(reorderProxiesController));
proxyRoutes.get("/admin/proxies/:id", validate(idParamSchema, "params"), asyncHandler(getProxyByIdController));
proxyRoutes.patch(
  "/admin/proxies/:id",
  validate(idParamSchema, "params"),
  validate(updateProxySchema),
  asyncHandler(updateProxyController),
);
proxyRoutes.patch(
  "/admin/proxies/:id/status",
  validate(idParamSchema, "params"),
  validate(updateProxyStatusSchema),
  asyncHandler(updateProxyStatusController),
);
proxyRoutes.delete("/admin/proxies/:id", validate(idParamSchema, "params"), asyncHandler(deleteProxyController));
