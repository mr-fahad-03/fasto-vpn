import { Types } from "mongoose";
import { PLAN_METADATA } from "../config/plans";
import { SubscriptionDoc, SubscriptionModel } from "../models/Subscription";
import { UserDoc, UserModel } from "../models/User";
import { buildRevenueCatAppUserId, parseRevenueCatAppUserId } from "../utils/identity";
import { getFreePlanRuntimeConfig } from "./settingsService";

const PREMIUM_EVENT_TYPES = new Set([
  "INITIAL_PURCHASE",
  "RENEWAL",
  "UNCANCELLATION",
]);

const CANCELLED_EVENT_TYPES = new Set([
  "CANCELLATION",
  "BILLING_ISSUE",
  "TRANSFER",
]);

type RevenueCatEventPayload = {
  event: {
    id?: string;
    type: string;
    app_user_id: string;
    entitlement_ids?: string[];
    product_id?: string;
    expiration_at_ms?: number | null;
    event_timestamp_ms?: number | null;
  };
};

type ProviderState = {
  sourceEntitlementId: "free" | "premium";
  sourceStatus: "free" | "premium" | "expired" | "cancelled";
  sourceIsPremium: boolean;
  sourceAdsEnabled: boolean;
};

type EffectiveState = {
  entitlementId: "free" | "premium";
  status: "free" | "premium" | "expired" | "cancelled";
  isPremium: boolean;
  adsEnabled: boolean;
};

type MobilePlan = {
  plan: "free" | "premium";
  hasPremium: boolean;
  adsEnabled: boolean;
  userId: string;
  rcAppUserId: string;
  status: "free" | "premium" | "expired" | "cancelled";
  expiresAt?: Date;
};

function toDateOrUndefined(ms?: number | null): Date | undefined {
  if (!ms) {
    return undefined;
  }

  return new Date(ms);
}

function deriveProviderState(event: RevenueCatEventPayload["event"]): ProviderState {
  const entitlementIds = event.entitlement_ids ?? [];
  const entitlementIsPremium = entitlementIds.includes("premium");
  const expiresAt = toDateOrUndefined(event.expiration_at_ms);
  const nowMs = Date.now();
  const notExpired = !expiresAt || expiresAt.getTime() > nowMs;

  if (event.type === "EXPIRATION") {
    return {
      sourceEntitlementId: "free",
      sourceStatus: "expired",
      sourceIsPremium: false,
      sourceAdsEnabled: true,
    };
  }

  if (PREMIUM_EVENT_TYPES.has(event.type)) {
    return {
      sourceEntitlementId: "premium",
      sourceStatus: "premium",
      sourceIsPremium: true,
      sourceAdsEnabled: false,
    };
  }

  if (event.type === "PRODUCT_CHANGE") {
    return {
      sourceEntitlementId: entitlementIsPremium ? "premium" : "free",
      sourceStatus: entitlementIsPremium ? "premium" : "free",
      sourceIsPremium: entitlementIsPremium,
      sourceAdsEnabled: !entitlementIsPremium,
    };
  }

  if (CANCELLED_EVENT_TYPES.has(event.type)) {
    const sourceIsPremium = entitlementIsPremium || notExpired;
    return {
      sourceEntitlementId: sourceIsPremium ? "premium" : "free",
      sourceStatus: "cancelled",
      sourceIsPremium,
      sourceAdsEnabled: !sourceIsPremium,
    };
  }

  return {
    sourceEntitlementId: entitlementIsPremium ? "premium" : "free",
    sourceStatus: entitlementIsPremium ? "premium" : "free",
    sourceIsPremium: entitlementIsPremium,
    sourceAdsEnabled: !entitlementIsPremium,
  };
}

function resolveEffectiveState(provider: ProviderState, expiresAt?: Date): EffectiveState {
  const hasPremium = provider.sourceIsPremium && (!expiresAt || expiresAt.getTime() > Date.now());

  if (provider.sourceStatus === "expired") {
    return {
      entitlementId: "free",
      status: "expired",
      isPremium: false,
      adsEnabled: true,
    };
  }

  if (!hasPremium && provider.sourceStatus === "cancelled") {
    return {
      entitlementId: "free",
      status: "cancelled",
      isPremium: false,
      adsEnabled: true,
    };
  }

  return {
    entitlementId: hasPremium ? "premium" : "free",
    status: hasPremium ? "premium" : "free",
    isPremium: hasPremium,
    adsEnabled: !hasPremium,
  };
}

async function resolveUserFromRevenueCatAppUserId(appUserId: string): Promise<UserDoc> {
  const parsed = parseRevenueCatAppUserId(appUserId);

  if (parsed.userId) {
    const existingById = await UserModel.findById(parsed.userId);
    if (existingById) {
      existingById.lastSeenAt = new Date();
      await existingById.save();
      return existingById;
    }

    const userId = new Types.ObjectId(parsed.userId);

    try {
      return await UserModel.create({
        _id: userId,
        mode: "mobile",
        isActive: true,
        lastSeenAt: new Date(),
      });
    } catch {
      const retry = await UserModel.findById(parsed.userId);
      if (retry) {
        retry.lastSeenAt = new Date();
        await retry.save();
        return retry;
      }
      throw new Error("Unable to resolve user for RevenueCat app user id");
    }
  }

  if (!parsed.firebaseUid) {
    throw new Error("Missing RevenueCat app user id");
  }

  const existingByFirebase = await UserModel.findOne({ firebaseUid: parsed.firebaseUid });
  if (existingByFirebase) {
    existingByFirebase.lastSeenAt = new Date();
    await existingByFirebase.save();
    return existingByFirebase;
  }

  return UserModel.create({
    mode: "mobile",
    firebaseUid: parsed.firebaseUid,
    isActive: true,
    lastSeenAt: new Date(),
  });
}

function isSubscriptionPremium(doc: SubscriptionDoc | null): boolean {
  if (!doc || !doc.isPremium) {
    return false;
  }

  if (!doc.expiresAt) {
    return true;
  }

  return doc.expiresAt.getTime() > Date.now();
}

export async function hasPremiumAccess(userId: string): Promise<boolean> {
  const subscription = await SubscriptionModel.findOne({ user: userId }).lean();
  return isSubscriptionPremium(subscription as SubscriptionDoc | null);
}

export async function getPlanForUser(userId: string): Promise<MobilePlan> {
  const subscription = await SubscriptionModel.findOne({ user: userId }).lean();
  const premium = isSubscriptionPremium(subscription as SubscriptionDoc | null);

  if (premium) {
    return {
      plan: "premium",
      hasPremium: true,
      adsEnabled: PLAN_METADATA.premium.adsEnabled,
      userId,
      rcAppUserId: buildRevenueCatAppUserId(userId),
      status: (subscription?.status as MobilePlan["status"]) ?? "premium",
      expiresAt: subscription?.expiresAt ?? undefined,
    };
  }

  const freeConfig = await getFreePlanRuntimeConfig();
  return {
    plan: "free",
    hasPremium: false,
    adsEnabled: freeConfig.adsEnabled,
    userId,
    rcAppUserId: buildRevenueCatAppUserId(userId),
    status: (subscription?.status as MobilePlan["status"]) ?? "free",
    expiresAt: subscription?.expiresAt ?? undefined,
  };
}

export async function processRevenueCatEvent(payload: RevenueCatEventPayload): Promise<void> {
  const event = payload.event;

  if (!event?.app_user_id) {
    return;
  }

  const user = await resolveUserFromRevenueCatAppUserId(event.app_user_id);
  const canonicalRcAppUserId = buildRevenueCatAppUserId(user._id.toString());
  const providerState = deriveProviderState(event);
  const expiresAt = toDateOrUndefined(event.expiration_at_ms);
  const eventId = event.id?.trim();
  const eventAt = toDateOrUndefined(event.event_timestamp_ms) ?? new Date();

  const existing = await SubscriptionModel.findOne({ user: user._id });
  const overrideActive = Boolean(existing?.manualOverride?.isActive);

  if (existing) {
    if (eventId && existing.lastEventId && existing.lastEventId === eventId) {
      return;
    }

    if (existing.lastEventAt && eventAt.getTime() < existing.lastEventAt.getTime()) {
      return;
    }
  }

  const effectiveState = resolveEffectiveState(providerState, expiresAt);

  const baseSet = {
    user: user._id,
    provider: "revenuecat" as const,
    revenueCatAppUserId: canonicalRcAppUserId,
    productId: event.product_id,
    sourceEntitlementId: providerState.sourceEntitlementId,
    sourceStatus: providerState.sourceStatus,
    sourceIsPremium: providerState.sourceIsPremium,
    sourceAdsEnabled: providerState.sourceAdsEnabled,
    planPriceUsd: PLAN_METADATA.premium.priceUsd,
    currency: PLAN_METADATA.premium.currency,
    expiresAt,
    lastEventType: event.type,
    lastEventId: eventId,
    lastEventAt: eventAt,
    rawEvent: payload,
  };

  if (overrideActive) {
    await SubscriptionModel.updateOne(
      { user: user._id },
      {
        $set: {
          ...baseSet,
        },
      },
      { upsert: true },
    );
    return;
  }

  await SubscriptionModel.updateOne(
    { user: user._id },
    {
      $set: {
        ...baseSet,
        entitlementId: effectiveState.entitlementId,
        status: effectiveState.status,
        isPremium: effectiveState.isPremium,
        adsEnabled: effectiveState.adsEnabled,
      },
    },
    { upsert: true },
  );
}
