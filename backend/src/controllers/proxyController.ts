import { Request, Response } from "express";
import {
  bulkImportProxies,
  connectMobileProxy,
  createProxy,
  deleteProxy,
  getPlanMetadataSummary,
  getProxyById,
  listAdminProxies,
  listMobileProxies,
  reorderProxies,
  updateProxy,
  updateProxyStatus,
} from "../services/proxyService";
import { logActivity } from "../utils/activity";

export async function createProxyController(req: Request, res: Response): Promise<void> {
  const data = await createProxy(req.body, req.admin!.id);

  await logActivity({
    eventType: "proxy.create",
    metadata: { proxyId: data.id, name: data.name },
    ip: req.ip,
    userAgent: req.header("user-agent") ?? undefined,
  });

  res.status(201).json({ success: true, data });
}

export async function updateProxyController(req: Request, res: Response): Promise<void> {
  const data = await updateProxy(String(req.params.id), req.body, req.admin!.id);

  await logActivity({
    eventType: "proxy.update",
    metadata: { proxyId: data.id, name: data.name },
    ip: req.ip,
    userAgent: req.header("user-agent") ?? undefined,
  });

  res.status(200).json({ success: true, data });
}

export async function deleteProxyController(req: Request, res: Response): Promise<void> {
  await deleteProxy(String(req.params.id));

  await logActivity({
    eventType: "proxy.delete",
    metadata: { proxyId: req.params.id },
    ip: req.ip,
    userAgent: req.header("user-agent") ?? undefined,
  });

  res.status(200).json({ success: true });
}

export async function getProxyByIdController(req: Request, res: Response): Promise<void> {
  const data = await getProxyById(String(req.params.id));
  res.status(200).json({ success: true, data });
}

export async function listAdminProxiesController(req: Request, res: Response): Promise<void> {
  const data = await listAdminProxies(req.query as Record<string, string>);
  res.status(200).json({ success: true, data });
}

export async function updateProxyStatusController(req: Request, res: Response): Promise<void> {
  const data = await updateProxyStatus(String(req.params.id), req.body.status);
  res.status(200).json({ success: true, data });
}

export async function reorderProxiesController(req: Request, res: Response): Promise<void> {
  await reorderProxies(req.body.items);
  res.status(200).json({ success: true });
}

export async function bulkImportProxiesController(req: Request, res: Response): Promise<void> {
  const data = await bulkImportProxies({
    items: req.body.items,
    rawText: req.body.rawText,
    defaults: req.body.defaults,
    adminId: req.admin!.id,
  });

  await logActivity({
    eventType: "proxy.bulk_import",
    metadata: { imported: data.imported },
    ip: req.ip,
    userAgent: req.header("user-agent") ?? undefined,
  });

  res.status(201).json({ success: true, data });
}

export async function mobileProxyListController(req: Request, res: Response): Promise<void> {
  const entitlement = req.entitlement!;
  const planMetadata = await getPlanMetadataSummary();
  const items = await listMobileProxies({
    hasPremium: entitlement.hasPremium,
    limitOverride: entitlement.proxyLimit,
  });

  await logActivity({
    userId: req.mobileAuth?.userId,
    eventType: "mobile.proxy.list",
    metadata: { plan: entitlement.plan, count: items.length },
    ip: req.ip,
    userAgent: req.header("user-agent") ?? undefined,
  });

  res.status(200).json({
    success: true,
    data: {
      plan: entitlement.plan,
      hasPremium: entitlement.hasPremium,
      adsEnabled: entitlement.adsEnabled,
      status: entitlement.status,
      expiresAt: entitlement.expiresAt,
      userId: entitlement.userId,
      rcAppUserId: entitlement.rcAppUserId,
      planMetadata,
      items,
    },
  });
}

export async function mobileProxyConnectController(req: Request, res: Response): Promise<void> {
  const entitlement = req.entitlement!;
  const mobile = req.mobileAuth;
  const proxyId = String(req.body.proxyId);

  const connected = await connectMobileProxy({
    proxyId,
    hasPremium: entitlement.hasPremium,
  });

  await logActivity({
    userId: mobile?.userId,
    eventType: "mobile.proxy.connect",
    metadata: {
      proxyId: connected.id,
      country: connected.country,
      countryCode: connected.countryCode,
      plan: entitlement.plan,
    },
    ip: req.ip,
    userAgent: req.header("user-agent") ?? undefined,
  });

  res.status(200).json({
    success: true,
    data: {
      connected: true,
      proxyId: connected.id,
      country: connected.country,
      countryCode: connected.countryCode,
      connect: connected.connect,
      connectedAt: new Date().toISOString(),
    },
  });
}
