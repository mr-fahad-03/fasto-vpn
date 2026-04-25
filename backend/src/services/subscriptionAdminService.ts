import { FilterQuery } from "mongoose";
import { SubscriptionDoc, SubscriptionModel } from "../models/Subscription";
import { ApiError } from "../utils/ApiError";
import { parsePagination } from "../utils/pagination";

function serializeSubscription(doc: SubscriptionDoc & { user?: any }) {
  return {
    id: doc._id.toString(),
    user: doc.user && typeof doc.user === "object"
      ? {
          id: doc.user._id?.toString?.() ?? doc.user.toString?.(),
          mode: doc.user.mode,
          email: doc.user.email,
          firebaseUid: doc.user.firebaseUid,
          isActive: doc.user.isActive,
        }
      : doc.user,
    provider: doc.provider,
    revenueCatAppUserId: doc.revenueCatAppUserId,
    productId: doc.productId,
    entitlementId: doc.entitlementId,
    status: doc.status,
    isPremium: doc.isPremium,
    adsEnabled: doc.adsEnabled,
    planPriceUsd: doc.planPriceUsd,
    currency: doc.currency,
    expiresAt: doc.expiresAt,
    sourceEntitlementId: doc.sourceEntitlementId,
    sourceStatus: doc.sourceStatus,
    sourceIsPremium: doc.sourceIsPremium,
    sourceAdsEnabled: doc.sourceAdsEnabled,
    manualOverride: doc.manualOverride,
    lastEventType: doc.lastEventType,
    lastEventId: doc.lastEventId,
    lastEventAt: doc.lastEventAt,
    createdAt: doc.createdAt,
    updatedAt: doc.updatedAt,
  };
}

export async function listSubscriptionsAdmin(params: {
  page?: string;
  limit?: string;
  search?: string;
  status?: string;
  isPremium?: string;
  overrideActive?: string;
  sortBy?: string;
  sortOrder?: "asc" | "desc";
}) {
  const { page, limit, skip } = parsePagination(params.page, params.limit);
  const filter: FilterQuery<SubscriptionDoc> = {};

  if (params.status) {
    filter.status = params.status as SubscriptionDoc["status"];
  }

  if (params.isPremium === "true") {
    filter.isPremium = true;
  }

  if (params.isPremium === "false") {
    filter.isPremium = false;
  }

  if (params.overrideActive === "true") {
    filter["manualOverride.isActive"] = true;
  }

  if (params.overrideActive === "false") {
    filter["manualOverride.isActive"] = false;
  }

  if (params.search) {
    filter.$or = [
      { revenueCatAppUserId: { $regex: params.search, $options: "i" } },
      { productId: { $regex: params.search, $options: "i" } },
      { entitlementId: { $regex: params.search, $options: "i" } },
    ];
  }

  const allowedSortFields = new Set(["createdAt", "updatedAt", "expiresAt", "status"]);
  const sortField = allowedSortFields.has(params.sortBy ?? "") ? params.sortBy! : "updatedAt";
  const sort: Record<string, 1 | -1> = { [sortField]: params.sortOrder === "asc" ? 1 : -1 };

  const [items, total] = await Promise.all([
    SubscriptionModel.find(filter).populate("user", "mode email firebaseUid isActive").sort(sort).skip(skip).limit(limit),
    SubscriptionModel.countDocuments(filter),
  ]);

  return {
    items: items.map((item) => serializeSubscription(item as SubscriptionDoc & { user?: any })),
    page,
    limit,
    total,
    totalPages: Math.ceil(total / limit),
  };
}

export async function setSubscriptionOverride(params: {
  subscriptionId: string;
  plan: "free" | "premium";
  reason?: string;
  adminId: string;
}) {
  const isPremium = params.plan === "premium";

  const updated = await SubscriptionModel.findByIdAndUpdate(
    params.subscriptionId,
    {
      $set: {
        entitlementId: params.plan,
        status: isPremium ? "premium" : "free",
        isPremium,
        adsEnabled: !isPremium,
        manualOverride: {
          isActive: true,
          plan: params.plan,
          reason: params.reason,
          setByAdmin: params.adminId,
          setAt: new Date(),
        },
      },
    },
    { new: true },
  ).populate("user", "mode email firebaseUid isActive");

  if (!updated) {
    throw new ApiError(404, "Subscription not found");
  }

  return serializeSubscription(updated as SubscriptionDoc & { user?: any });
}

export async function clearSubscriptionOverride(subscriptionId: string) {
  const sub = await SubscriptionModel.findById(subscriptionId);
  if (!sub) {
    throw new ApiError(404, "Subscription not found");
  }

  sub.manualOverride = {
    isActive: false,
    plan: undefined,
    reason: undefined,
    setByAdmin: undefined,
    setAt: undefined,
  };

  sub.entitlementId = sub.sourceEntitlementId ?? "free";
  sub.status = sub.sourceStatus ?? "free";
  sub.isPremium = Boolean(sub.sourceIsPremium);
  sub.adsEnabled = sub.sourceAdsEnabled ?? !sub.sourceIsPremium;

  await sub.save();
  await sub.populate("user", "mode email firebaseUid isActive");

  return serializeSubscription(sub as SubscriptionDoc & { user?: any });
}
