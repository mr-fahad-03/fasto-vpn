import mongoose, { InferSchemaType, Model } from "mongoose";

const PROXY_TYPES = ["HTTP", "SOCKS5"] as const;
const GEO_LOOKUP_STATUSES = ["success", "fallback", "failed"] as const;
const PROXY_STATUSES = ["active", "inactive"] as const;
const HEALTH_STATUSES = ["unknown", "healthy", "degraded", "down"] as const;

const proxySchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    host: { type: String, required: true, trim: true },
    ip: { type: String, trim: true },
    port: { type: Number, required: true, min: 1, max: 65535 },
    type: { type: String, enum: PROXY_TYPES, default: "HTTP" },
    username: { type: String, trim: true },
    password: { type: String, trim: true },

    country: { type: String, default: "Unknown" },
    countryCode: { type: String, default: "XX" },
    city: { type: String },
    region: { type: String },
    timezone: { type: String },
    isp: { type: String },
    asn: { type: String },
    geoLookupRaw: { type: mongoose.Schema.Types.Mixed },
    geoLookupProvider: { type: String, default: "ipwho.is" },
    geoLookupStatus: {
      type: String,
      enum: GEO_LOOKUP_STATUSES,
      default: "fallback",
    },
    geoLookupError: { type: String },

    status: { type: String, enum: PROXY_STATUSES, default: "active" },
    isPremium: { type: Boolean, default: false },
    sortOrder: { type: Number, default: 0 },
    tags: { type: [String], default: [] },
    latency: { type: Number, default: 0 },
    healthStatus: {
      type: String,
      enum: HEALTH_STATUSES,
      default: "unknown",
    },
    maxFreeVisible: { type: Boolean, default: true },

    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: "Admin" },
    updatedBy: { type: mongoose.Schema.Types.ObjectId, ref: "Admin" },
  },
  {
    timestamps: true,
    versionKey: false,
  },
);

proxySchema.index({ status: 1, isPremium: 1, sortOrder: 1 });
proxySchema.index({ isPremium: 1, status: 1, maxFreeVisible: 1, sortOrder: 1 });
proxySchema.index({ countryCode: 1 });
proxySchema.index({ healthStatus: 1, status: 1 });
proxySchema.index({ updatedAt: -1 });
proxySchema.index({ name: "text", host: "text", country: "text", city: "text", isp: "text", tags: "text" });

proxySchema.virtual("id").get(function proxyId(this: { _id: mongoose.Types.ObjectId }) {
  return this._id.toString();
});

proxySchema.set("toJSON", { virtuals: true });
proxySchema.set("toObject", { virtuals: true });

export type ProxyDoc = InferSchemaType<typeof proxySchema> & { _id: mongoose.Types.ObjectId };

export const ProxyModel: Model<ProxyDoc> =
  (mongoose.models.Proxy as Model<ProxyDoc>) || mongoose.model<ProxyDoc>("Proxy", proxySchema);
