import mongoose, { InferSchemaType, Model } from "mongoose";

const SESSION_TYPES = ["guest", "mobile"] as const;

const deviceSessionSchema = new mongoose.Schema(
  {
    sessionId: { type: String, required: true, unique: true, index: true },
    user: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    type: { type: String, enum: SESSION_TYPES, required: true },
    firebaseUid: { type: String },
    deviceId: { type: String },
    platform: { type: String },
    ip: { type: String },
    userAgent: { type: String },
    lastActiveAt: { type: Date, default: Date.now },
    revokedAt: { type: Date },
  },
  {
    timestamps: true,
    versionKey: false,
  },
);

deviceSessionSchema.index({ type: 1, revokedAt: 1, sessionId: 1 });
deviceSessionSchema.index({ user: 1, revokedAt: 1, lastActiveAt: -1 });
deviceSessionSchema.index({ firebaseUid: 1 }, { sparse: true });

deviceSessionSchema.virtual("id").get(function deviceSessionId(this: { _id: mongoose.Types.ObjectId }) {
  return this._id.toString();
});

deviceSessionSchema.virtual("isRevoked").get(function isRevoked(this: { revokedAt?: Date }) {
  return Boolean(this.revokedAt);
});

deviceSessionSchema.set("toJSON", { virtuals: true });
deviceSessionSchema.set("toObject", { virtuals: true });

export type DeviceSessionDoc = InferSchemaType<typeof deviceSessionSchema> & {
  _id: mongoose.Types.ObjectId;
};

export const DeviceSessionModel: Model<DeviceSessionDoc> =
  (mongoose.models.DeviceSession as Model<DeviceSessionDoc>) ||
  mongoose.model<DeviceSessionDoc>("DeviceSession", deviceSessionSchema);
