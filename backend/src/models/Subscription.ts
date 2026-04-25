import mongoose, { InferSchemaType, Model } from "mongoose";

const SUBSCRIPTION_PROVIDERS = ["revenuecat"] as const;
const SUBSCRIPTION_STATUSES = ["free", "premium", "expired", "cancelled"] as const;
const ENTITLEMENTS = ["free", "premium"] as const;

const subscriptionSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, unique: true },
    provider: { type: String, enum: SUBSCRIPTION_PROVIDERS, default: "revenuecat" },
    revenueCatAppUserId: { type: String, index: true },
    productId: { type: String },

    entitlementId: { type: String, enum: ENTITLEMENTS, default: "free" },
    status: {
      type: String,
      enum: SUBSCRIPTION_STATUSES,
      default: "free",
    },
    isPremium: { type: Boolean, default: false },
    planPriceUsd: { type: Number, default: 9.99 },
    currency: { type: String, default: "USD" },
    adsEnabled: { type: Boolean, default: true },
    expiresAt: { type: Date },

    sourceEntitlementId: { type: String, enum: ENTITLEMENTS, default: "free" },
    sourceStatus: {
      type: String,
      enum: SUBSCRIPTION_STATUSES,
      default: "free",
    },
    sourceIsPremium: { type: Boolean, default: false },
    sourceAdsEnabled: { type: Boolean, default: true },

    manualOverride: {
      isActive: { type: Boolean, default: false },
      plan: { type: String, enum: ENTITLEMENTS },
      reason: { type: String },
      setByAdmin: { type: mongoose.Schema.Types.ObjectId, ref: "Admin" },
      setAt: { type: Date },
    },

    lastEventType: { type: String },
    lastEventId: { type: String },
    lastEventAt: { type: Date },
    rawEvent: { type: mongoose.Schema.Types.Mixed },
  },
  {
    timestamps: true,
    versionKey: false,
  },
);

subscriptionSchema.index({ isPremium: 1, status: 1 });
subscriptionSchema.index({ "manualOverride.isActive": 1 });
subscriptionSchema.index({ expiresAt: 1, status: 1 });
subscriptionSchema.index({ lastEventAt: -1 });

subscriptionSchema.virtual("id").get(function subscriptionId(this: { _id: mongoose.Types.ObjectId }) {
  return this._id.toString();
});

subscriptionSchema.virtual("isEffectivelyPremium").get(
  function isEffectivelyPremium(this: {
    manualOverride?: { isActive?: boolean; plan?: string };
    isPremium: boolean;
    expiresAt?: Date;
  }) {
    if (this.manualOverride?.isActive) {
      return this.manualOverride.plan === "premium";
    }

    if (!this.isPremium) {
      return false;
    }

    return !this.expiresAt || this.expiresAt.getTime() > Date.now();
  },
);

subscriptionSchema.set("toJSON", { virtuals: true });
subscriptionSchema.set("toObject", { virtuals: true });

export type SubscriptionDoc = InferSchemaType<typeof subscriptionSchema> & {
  _id: mongoose.Types.ObjectId;
};

export const SubscriptionModel: Model<SubscriptionDoc> =
  (mongoose.models.Subscription as Model<SubscriptionDoc>) ||
  mongoose.model<SubscriptionDoc>("Subscription", subscriptionSchema);
