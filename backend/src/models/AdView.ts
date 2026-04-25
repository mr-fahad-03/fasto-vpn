import mongoose, { InferSchemaType, Model } from "mongoose";

const AD_PLATFORMS = ["android", "ios", "web", "unknown"] as const;

const adViewSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
    placement: { type: String, required: true },
    provider: { type: String, default: "admob" },
    platform: { type: String, enum: AD_PLATFORMS, default: "unknown" },
    revenueMicros: { type: Number, default: 0 },
    viewedAt: { type: Date, default: Date.now },
  },
  {
    timestamps: true,
    versionKey: false,
  },
);

adViewSchema.index({ viewedAt: -1 });
adViewSchema.index({ user: 1, viewedAt: -1 });
adViewSchema.index({ placement: 1, viewedAt: -1 });
adViewSchema.index({ provider: 1, viewedAt: -1 });

adViewSchema.virtual("id").get(function adViewId(this: { _id: mongoose.Types.ObjectId }) {
  return this._id.toString();
});

adViewSchema.virtual("revenueUsd").get(function revenueUsd(this: { revenueMicros: number }) {
  return this.revenueMicros / 1_000_000;
});

adViewSchema.set("toJSON", { virtuals: true });
adViewSchema.set("toObject", { virtuals: true });

export type AdViewDoc = InferSchemaType<typeof adViewSchema> & { _id: mongoose.Types.ObjectId };

export const AdViewModel: Model<AdViewDoc> =
  (mongoose.models.AdView as Model<AdViewDoc>) || mongoose.model<AdViewDoc>("AdView", adViewSchema);
