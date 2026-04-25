import { AppConfigModel } from "../models/AppConfig";

export type AdminPanelSettings = {
  freePlanAdsEnabled: boolean;
  maxFreeProxiesCount: number;
  featuredCountries: string[];
  appNotices: string[];
};

const SETTINGS_KEY = "admin.panel.settings";

const DEFAULT_SETTINGS: AdminPanelSettings = {
  freePlanAdsEnabled: true,
  maxFreeProxiesCount: 20,
  featuredCountries: ["DE", "NL", "US"],
  appNotices: [],
};

export async function ensureAdminPanelSettings(): Promise<void> {
  await AppConfigModel.updateOne(
    { key: SETTINGS_KEY },
    {
      $setOnInsert: {
        key: SETTINGS_KEY,
        value: DEFAULT_SETTINGS,
        description: "Consolidated admin panel settings",
      },
    },
    { upsert: true },
  );
}

export async function getAdminSettings(): Promise<AdminPanelSettings> {
  await ensureAdminPanelSettings();
  const config = await AppConfigModel.findOne({ key: SETTINGS_KEY }).lean();
  const value = config?.value as Partial<AdminPanelSettings> | undefined;

  return {
    freePlanAdsEnabled: value?.freePlanAdsEnabled ?? DEFAULT_SETTINGS.freePlanAdsEnabled,
    maxFreeProxiesCount: value?.maxFreeProxiesCount ?? DEFAULT_SETTINGS.maxFreeProxiesCount,
    featuredCountries: value?.featuredCountries ?? DEFAULT_SETTINGS.featuredCountries,
    appNotices: value?.appNotices ?? DEFAULT_SETTINGS.appNotices,
  };
}

export async function updateAdminSettings(input: AdminPanelSettings): Promise<AdminPanelSettings> {
  await AppConfigModel.updateOne(
    { key: SETTINGS_KEY },
    {
      $set: {
        key: SETTINGS_KEY,
        value: {
          freePlanAdsEnabled: input.freePlanAdsEnabled,
          maxFreeProxiesCount: input.maxFreeProxiesCount,
          featuredCountries: input.featuredCountries,
          appNotices: input.appNotices,
        },
        description: "Consolidated admin panel settings",
      },
    },
    { upsert: true },
  );

  return getAdminSettings();
}

export async function getFreePlanRuntimeConfig(): Promise<{
  adsEnabled: boolean;
  maxFreeProxiesCount: number;
}> {
  const settings = await getAdminSettings();
  return {
    adsEnabled: settings.freePlanAdsEnabled,
    maxFreeProxiesCount: settings.maxFreeProxiesCount,
  };
}
