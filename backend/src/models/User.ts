import mongoose, { HydratedDocument, InferSchemaType, Model } from "mongoose";

const USER_MODES = ["guest", "mobile"] as const;

const userSchema = new mongoose.Schema(
  {
    mode: { type: String, enum: USER_MODES, required: true },
    firebaseUid: { type: String, index: true, sparse: true, unique: true },
    email: { type: String, trim: true, lowercase: true },
    displayName: { type: String, trim: true },
    guestSessionId: { type: String, index: true, sparse: true, unique: true },
    isActive: { type: Boolean, default: true },
    lastSeenAt: { type: Date, default: Date.now },
    mergedIntoUserId: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
    mergedAt: { type: Date },
  },
  {
    timestamps: true,
    versionKey: false,
  },
);

userSchema.index({ mode: 1, isActive: 1, createdAt: -1 });
userSchema.index({ lastSeenAt: -1 });
userSchema.index({ mergedIntoUserId: 1, mergedAt: -1 });

userSchema.virtual("id").get(function userId(this: { _id: mongoose.Types.ObjectId }) {
  return this._id.toString();
});

userSchema.virtual("isMerged").get(function isMerged(this: { mergedIntoUserId?: mongoose.Types.ObjectId }) {
  return Boolean(this.mergedIntoUserId);
});

userSchema.set("toJSON", { virtuals: true });
userSchema.set("toObject", { virtuals: true });

export type UserDoc = HydratedDocument<InferSchemaType<typeof userSchema>>;

export const UserModel: Model<UserDoc> =
  (mongoose.models.User as Model<UserDoc>) || mongoose.model<UserDoc>("User", userSchema);
