import { NextFunction, Request, Response } from "express";
import { PLAN_METADATA } from "../config/plans";
import { getPlanForUser } from "../services/subscriptionService";
import { getFreePlanRuntimeConfig } from "../services/settingsService";

export async function resolveEntitlement(req: Request, _res: Response, next: NextFunction): Promise<void> {
  const freeConfig = await getFreePlanRuntimeConfig();

  if (!req.mobileAuth) {
    req.entitlement = {
      plan: "free",
      hasPremium: false,
      adsEnabled: freeConfig.adsEnabled,
      proxyLimit: freeConfig.maxFreeProxiesCount,
      status: "free",
      userId: undefined,
      rcAppUserId: undefined,
      expiresAt: undefined,
    };
    return next();
  }

  const plan = await getPlanForUser(req.mobileAuth.userId);

  if (plan.hasPremium) {
    req.entitlement = {
      plan: "premium",
      hasPremium: true,
      adsEnabled: PLAN_METADATA.premium.adsEnabled,
      proxyLimit: PLAN_METADATA.premium.proxyLimit,
      status: plan.status,
      expiresAt: plan.expiresAt,
      userId: plan.userId,
      rcAppUserId: plan.rcAppUserId,
    };
    return next();
  }

  req.entitlement = {
    plan: "free",
    hasPremium: false,
    adsEnabled: freeConfig.adsEnabled,
    proxyLimit: freeConfig.maxFreeProxiesCount,
    status: plan.status,
    expiresAt: plan.expiresAt,
    userId: plan.userId,
    rcAppUserId: plan.rcAppUserId,
  };

  next();
}
