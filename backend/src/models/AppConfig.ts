import mongoose, { InferSchemaType, Model } from "mongoose";

const CONFIG_SCOPES = ["plan", "settings", "system", "other"] as const;
const CONFIG_VALUE_TYPES = ["object", "string", "number", "boolean", "array", "mixed"] as const;

const appConfigSchema = new mongoose.Schema(
  {
    key: { type: String, required: true, unique: true, trim: true },
    value: { type: mongoose.Schema.Types.Mixed, required: true },
    description: { type: String, trim: true },
    scope: { type: String, enum: CONFIG_SCOPES, default: "other" },
    valueType: { type: String, enum: CONFIG_VALUE_TYPES, default: "mixed" },
    isPublic: { type: Boolean, default: false },
  },
  {
    timestamps: true,
    versionKey: false,
  },
);

appConfigSchema.index({ scope: 1, isPublic: 1, updatedAt: -1 });

appConfigSchema.virtual("id").get(function appConfigId(this: { _id: mongoose.Types.ObjectId }) {
  return this._id.toString();
});

appConfigSchema.set("toJSON", { virtuals: true });
appConfigSchema.set("toObject", { virtuals: true });

export type AppConfigDoc = InferSchemaType<typeof appConfigSchema> & { _id: mongoose.Types.ObjectId };

export const AppConfigModel: Model<AppConfigDoc> =
  (mongoose.models.AppConfig as Model<AppConfigDoc>) ||
  mongoose.model<AppConfigDoc>("AppConfig", appConfigSchema);
