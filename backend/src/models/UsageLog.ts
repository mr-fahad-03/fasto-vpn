import mongoose, { InferSchemaType, Model } from "mongoose";

const USAGE_SOURCES = ["admin", "mobile", "system", "webhook"] as const;
const USAGE_LEVELS = ["info", "warn", "error"] as const;

const usageLogSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
    eventType: { type: String, required: true, index: true },
    source: { type: String, enum: USAGE_SOURCES, default: "system" },
    level: { type: String, enum: USAGE_LEVELS, default: "info" },
    metadata: { type: mongoose.Schema.Types.Mixed },
    ip: { type: String },
    userAgent: { type: String },
  },
  {
    timestamps: true,
    versionKey: false,
  },
);

usageLogSchema.index({ createdAt: -1 });
usageLogSchema.index({ user: 1, createdAt: -1 });
usageLogSchema.index({ eventType: 1, createdAt: -1 });

usageLogSchema.virtual("id").get(function usageLogId(this: { _id: mongoose.Types.ObjectId }) {
  return this._id.toString();
});

usageLogSchema.set("toJSON", { virtuals: true });
usageLogSchema.set("toObject", { virtuals: true });

export type UsageLogDoc = InferSchemaType<typeof usageLogSchema> & { _id: mongoose.Types.ObjectId };

export const UsageLogModel: Model<UsageLogDoc> =
  (mongoose.models.UsageLog as Model<UsageLogDoc>) ||
  mongoose.model<UsageLogDoc>("UsageLog", usageLogSchema);
