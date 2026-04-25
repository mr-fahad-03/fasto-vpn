import { env } from "../config/env";
import { AppConfigModel } from "../models/AppConfig";
import { ensureAdminPanelSettings } from "./settingsService";

export async function ensureBaseAppConfig(): Promise<void> {
  await AppConfigModel.updateOne(
    { key: "plan.free" },
    {
      $set: {
        key: "plan.free",
        value: { adsEnabled: true, proxyLimit: env.FREE_PROXY_LIMIT },
        description: "Default free plan metadata",
      },
    },
    { upsert: true },
  );

  await AppConfigModel.updateOne(
    { key: "plan.premium" },
    {
      $set: {
        key: "plan.premium",
        value: { priceUsd: env.PREMIUM_PLAN_PRICE_USD, currency: "USD", adsEnabled: false },
        description: "Default premium plan metadata",
      },
    },
    { upsert: true },
  );

  await ensureAdminPanelSettings();
}
