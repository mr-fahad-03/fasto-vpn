import "dotenv/config";
import bcrypt from "bcryptjs";
import { env } from "../config/env";
import { connectDatabase, disconnectDatabase } from "../config/database";
import { AdminModel } from "../models/Admin";
import { AppConfigModel } from "../models/AppConfig";
import { ProxyModel } from "../models/Proxy";
import { SubscriptionModel } from "../models/Subscription";
import { UserModel } from "../models/User";
import { buildRevenueCatAppUserId } from "../utils/identity";

type SeedSummary = {
  admin: { created: number; updated: number };
  appConfig: { created: number; updated: number };
  proxies: { created: number; updated: number; total: number; free: number; premium: number };
  users: { created: number; updated: number; total: number; free: number; premium: number };
  subscriptions: { created: number; updated: number; total: number; free: number; premium: number };
  timestamp: string;
};

type SeedProxy = {
  name: string;
  host: string;
  port: number;
  country: string;
  countryCode: string;
  city: string;
  isPremium: boolean;
  sortOrder: number;
};

async function seedAdmin(): Promise<{ created: number; updated: number }> {
  const email = env.ADMIN_DEFAULT_EMAIL.toLowerCase().trim();
  const passwordHash = await bcrypt.hash(env.ADMIN_DEFAULT_PASSWORD, env.BCRYPT_SALT_ROUNDS);

  const existing = await AdminModel.findOne({ email });

  if (!existing) {
    await AdminModel.create({
      email,
      passwordHash,
      role: "admin",
      isActive: true,
      tokenVersion: 0,
    });
    return { created: 1, updated: 0 };
  }

  const result = await AdminModel.updateOne(
    { _id: existing._id },
    {
      $set: {
        role: "admin",
        isActive: true,
        passwordHash,
      },
    },
  );

  return {
    created: 0,
    updated: result.modifiedCount > 0 ? 1 : 0,
  };
}

async function seedAppConfig(): Promise<{ created: number; updated: number }> {
  const configs = [
    {
      key: "plan.free",
      value: { adsEnabled: true, proxyLimit: env.FREE_PROXY_LIMIT },
      description: "Default free plan metadata",
      scope: "plan",
      valueType: "object",
      isPublic: true,
    },
    {
      key: "plan.premium",
      value: { priceUsd: env.PREMIUM_PLAN_PRICE_USD, currency: "USD", adsEnabled: false },
      description: "Default premium plan metadata",
      scope: "plan",
      valueType: "object",
      isPublic: true,
    },
    {
      key: "admin.panel.settings",
      value: {
        freePlanAdsEnabled: true,
        maxFreeProxiesCount: env.FREE_PROXY_LIMIT,
        featuredCountries: ["DE", "NL", "US"],
        appNotices: [],
      },
      description: "Consolidated admin panel settings",
      scope: "settings",
      valueType: "object",
      isPublic: false,
    },
  ] as const;

  let created = 0;
  let updated = 0;

  for (const cfg of configs) {
    const result = await AppConfigModel.updateOne(
      { key: cfg.key },
      {
        $set: {
          key: cfg.key,
          value: cfg.value,
          description: cfg.description,
          scope: cfg.scope,
          valueType: cfg.valueType,
          isPublic: cfg.isPublic,
        },
      },
      { upsert: true },
    );

    if (result.upsertedCount > 0) {
      created += 1;
    } else if (result.modifiedCount > 0) {
      updated += 1;
    }
  }

  return { created, updated };
}

function buildProxyRows(): SeedProxy[] {
  const free: SeedProxy[] = [
    {
      name: "Germany Free 1",
      host: "149.154.167.91",
      port: 443,
      country: "Germany",
      countryCode: "DE",
      city: "Frankfurt",
      isPremium: false,
      sortOrder: 1,
    },
    {
      name: "Netherlands Free 1",
      host: "149.154.167.92",
      port: 443,
      country: "Netherlands",
      countryCode: "NL",
      city: "Amsterdam",
      isPremium: false,
      sortOrder: 2,
    },
    {
      name: "United States Free 1",
      host: "149.154.167.93",
      port: 443,
      country: "United States",
      countryCode: "US",
      city: "New York",
      isPremium: false,
      sortOrder: 3,
    },
    {
      name: "United Kingdom Free 1",
      host: "149.154.167.94",
      port: 443,
      country: "United Kingdom",
      countryCode: "GB",
      city: "London",
      isPremium: false,
      sortOrder: 4,
    },
    {
      name: "France Free 1",
      host: "149.154.167.95",
      port: 443,
      country: "France",
      countryCode: "FR",
      city: "Paris",
      isPremium: false,
      sortOrder: 5,
    },
    {
      name: "Singapore Free 1",
      host: "149.154.167.96",
      port: 443,
      country: "Singapore",
      countryCode: "SG",
      city: "Singapore",
      isPremium: false,
      sortOrder: 6,
    },
    {
      name: "Japan Free 1",
      host: "149.154.167.97",
      port: 443,
      country: "Japan",
      countryCode: "JP",
      city: "Tokyo",
      isPremium: false,
      sortOrder: 7,
    },
    {
      name: "India Free 1",
      host: "149.154.167.98",
      port: 443,
      country: "India",
      countryCode: "IN",
      city: "Mumbai",
      isPremium: false,
      sortOrder: 8,
    },
    {
      name: "Brazil Free 1",
      host: "149.154.167.99",
      port: 443,
      country: "Brazil",
      countryCode: "BR",
      city: "Sao Paulo",
      isPremium: false,
      sortOrder: 9,
    },
    {
      name: "Canada Free 1",
      host: "149.154.167.100",
      port: 443,
      country: "Canada",
      countryCode: "CA",
      city: "Toronto",
      isPremium: false,
      sortOrder: 10,
    },
  ];

  const premium: SeedProxy[] = [
    {
      name: "Germany Premium 1",
      host: "149.154.168.91",
      port: 443,
      country: "Germany",
      countryCode: "DE",
      city: "Berlin",
      isPremium: true,
      sortOrder: 11,
    },
    {
      name: "Netherlands Premium 1",
      host: "149.154.168.92",
      port: 443,
      country: "Netherlands",
      countryCode: "NL",
      city: "Rotterdam",
      isPremium: true,
      sortOrder: 12,
    },
    {
      name: "United States Premium 1",
      host: "149.154.168.93",
      port: 443,
      country: "United States",
      countryCode: "US",
      city: "Chicago",
      isPremium: true,
      sortOrder: 13,
    },
    {
      name: "United Kingdom Premium 1",
      host: "149.154.168.94",
      port: 443,
      country: "United Kingdom",
      countryCode: "GB",
      city: "Manchester",
      isPremium: true,
      sortOrder: 14,
    },
    {
      name: "France Premium 1",
      host: "149.154.168.95",
      port: 443,
      country: "France",
      countryCode: "FR",
      city: "Lyon",
      isPremium: true,
      sortOrder: 15,
    },
    {
      name: "Singapore Premium 1",
      host: "149.154.168.96",
      port: 443,
      country: "Singapore",
      countryCode: "SG",
      city: "Singapore",
      isPremium: true,
      sortOrder: 16,
    },
    {
      name: "Japan Premium 1",
      host: "149.154.168.97",
      port: 443,
      country: "Japan",
      countryCode: "JP",
      city: "Osaka",
      isPremium: true,
      sortOrder: 17,
    },
    {
      name: "India Premium 1",
      host: "149.154.168.98",
      port: 443,
      country: "India",
      countryCode: "IN",
      city: "Delhi",
      isPremium: true,
      sortOrder: 18,
    },
    {
      name: "Brazil Premium 1",
      host: "149.154.168.99",
      port: 443,
      country: "Brazil",
      countryCode: "BR",
      city: "Rio de Janeiro",
      isPremium: true,
      sortOrder: 19,
    },
    {
      name: "Canada Premium 1",
      host: "149.154.168.100",
      port: 443,
      country: "Canada",
      countryCode: "CA",
      city: "Vancouver",
      isPremium: true,
      sortOrder: 20,
    },
  ];

  return [...free, ...premium];
}

async function seedProxies(adminId: string): Promise<{
  created: number;
  updated: number;
  total: number;
  free: number;
  premium: number;
}> {
  const proxies = buildProxyRows();
  let created = 0;
  let updated = 0;

  for (const proxy of proxies) {
    const result = await ProxyModel.updateOne(
      { host: proxy.host, port: proxy.port },
      {
        $set: {
          name: proxy.name,
          host: proxy.host,
          port: proxy.port,
          type: proxy.isPremium ? "SOCKS5" : "HTTP",
          status: "active",
          isPremium: proxy.isPremium,
          sortOrder: proxy.sortOrder,
          tags: proxy.isPremium ? ["premium", "socks5"] : ["free", "http"],
          latency: proxy.isPremium ? 55 : 95,
          healthStatus: "healthy",
          maxFreeVisible: !proxy.isPremium,
          country: proxy.country,
          countryCode: proxy.countryCode,
          city: proxy.city,
          createdBy: adminId,
          updatedBy: adminId,
        },
      },
      { upsert: true },
    );

    if (result.upsertedCount > 0) {
      created += 1;
    } else if (result.modifiedCount > 0) {
      updated += 1;
    }
  }

  return {
    created,
    updated,
    total: proxies.length,
    free: proxies.filter((proxy) => !proxy.isPremium).length,
    premium: proxies.filter((proxy) => proxy.isPremium).length,
  };
}

async function seedUsersAndSubscriptions(): Promise<{
  users: { created: number; updated: number; total: number; free: number; premium: number };
  subscriptions: { created: number; updated: number; total: number; free: number; premium: number };
}> {
  const now = new Date();
  const nextMonth = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);

  const users = [
    {
      mode: "mobile" as const,
      email: "free.mobile@example.com",
      displayName: "Free Mobile User",
      firebaseUid: "seed-firebase-free-mobile",
      guestSessionId: undefined,
      plan: "free" as const,
    },
    {
      mode: "mobile" as const,
      email: "premium.mobile@example.com",
      displayName: "Premium Mobile User",
      firebaseUid: "seed-firebase-premium-mobile",
      guestSessionId: undefined,
      plan: "premium" as const,
    },
    {
      mode: "guest" as const,
      email: undefined,
      displayName: "Free Guest User",
      firebaseUid: undefined,
      guestSessionId: "seed-guest-session-free-user",
      plan: "free" as const,
    },
  ];

  let usersCreated = 0;
  let usersUpdated = 0;
  let subsCreated = 0;
  let subsUpdated = 0;
  let freeUsers = 0;
  let premiumUsers = 0;

  for (const row of users) {
    const lookup = row.firebaseUid ? { firebaseUid: row.firebaseUid } : { guestSessionId: row.guestSessionId };

    const userResult = await UserModel.updateOne(
      lookup,
      {
        $set: {
          mode: row.mode,
          email: row.email,
          displayName: row.displayName,
          firebaseUid: row.firebaseUid,
          guestSessionId: row.guestSessionId,
          isActive: true,
          lastSeenAt: now,
        },
      },
      { upsert: true },
    );

    if (userResult.upsertedCount > 0) {
      usersCreated += 1;
    } else if (userResult.modifiedCount > 0) {
      usersUpdated += 1;
    }

    const user = await UserModel.findOne(lookup).lean();
    if (!user) {
      throw new Error(`Failed to resolve seeded user for ${JSON.stringify(lookup)}`);
    }

    const isPremium = row.plan === "premium";
    if (isPremium) {
      premiumUsers += 1;
    } else {
      freeUsers += 1;
    }

    const subscriptionResult = await SubscriptionModel.updateOne(
      { user: user._id },
      {
        $set: {
          user: user._id,
          provider: "revenuecat",
          revenueCatAppUserId: buildRevenueCatAppUserId(user._id.toString()),
          productId: isPremium ? "fasto_premium_monthly" : undefined,
          entitlementId: isPremium ? "premium" : "free",
          status: isPremium ? "premium" : "free",
          isPremium,
          planPriceUsd: env.PREMIUM_PLAN_PRICE_USD,
          currency: "USD",
          adsEnabled: !isPremium,
          expiresAt: isPremium ? nextMonth : undefined,
          sourceEntitlementId: isPremium ? "premium" : "free",
          sourceStatus: isPremium ? "premium" : "free",
          sourceIsPremium: isPremium,
          sourceAdsEnabled: !isPremium,
          lastEventType: "seed",
          lastEventId: `seed-${user._id.toString()}`,
          lastEventAt: now,
          rawEvent: {
            source: "seed",
            seededAt: now.toISOString(),
          },
          manualOverride: {
            isActive: false,
            plan: undefined,
            reason: undefined,
            setByAdmin: undefined,
            setAt: undefined,
          },
        },
      },
      { upsert: true },
    );

    if (subscriptionResult.upsertedCount > 0) {
      subsCreated += 1;
    } else if (subscriptionResult.modifiedCount > 0) {
      subsUpdated += 1;
    }
  }

  return {
    users: {
      created: usersCreated,
      updated: usersUpdated,
      total: users.length,
      free: freeUsers,
      premium: premiumUsers,
    },
    subscriptions: {
      created: subsCreated,
      updated: subsUpdated,
      total: users.length,
      free: freeUsers,
      premium: premiumUsers,
    },
  };
}

async function run(): Promise<void> {
  await connectDatabase();

  const summary: SeedSummary = {
    admin: { created: 0, updated: 0 },
    appConfig: { created: 0, updated: 0 },
    proxies: { created: 0, updated: 0, total: 0, free: 0, premium: 0 },
    users: { created: 0, updated: 0, total: 0, free: 0, premium: 0 },
    subscriptions: { created: 0, updated: 0, total: 0, free: 0, premium: 0 },
    timestamp: new Date().toISOString(),
  };

  summary.admin = await seedAdmin();

  const admin = await AdminModel.findOne({ email: env.ADMIN_DEFAULT_EMAIL.toLowerCase().trim() });
  if (!admin) {
    throw new Error("Admin seeding failed");
  }

  summary.appConfig = await seedAppConfig();
  summary.proxies = await seedProxies(admin._id.toString());

  const seededUsers = await seedUsersAndSubscriptions();
  summary.users = seededUsers.users;
  summary.subscriptions = seededUsers.subscriptions;

  console.log("Seed complete.");
  console.log(JSON.stringify(summary, null, 2));

  await disconnectDatabase();
}

run().catch(async (error) => {
  console.error(error);
  await disconnectDatabase();
  process.exit(1);
});
