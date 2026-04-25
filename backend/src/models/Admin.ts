import mongoose, { InferSchemaType, Model } from "mongoose";

const ADMIN_ROLES = ["admin"] as const;

const adminSchema = new mongoose.Schema(
  {
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    passwordHash: { type: String, required: true },
    role: { type: String, enum: ADMIN_ROLES, default: "admin" },
    isActive: { type: Boolean, default: true },
    tokenVersion: { type: Number, default: 0 },
    lastLoginAt: { type: Date },
  },
  {
    timestamps: true,
    versionKey: false,
  },
);

adminSchema.index({ isActive: 1, createdAt: -1 });
adminSchema.index({ lastLoginAt: -1 });

adminSchema.virtual("id").get(function adminId(this: { _id: mongoose.Types.ObjectId }) {
  return this._id.toString();
});

adminSchema.set("toJSON", { virtuals: true });
adminSchema.set("toObject", { virtuals: true });

export type AdminDoc = InferSchemaType<typeof adminSchema> & { _id: mongoose.Types.ObjectId };

export const AdminModel: Model<AdminDoc> =
  (mongoose.models.Admin as Model<AdminDoc>) || mongoose.model<AdminDoc>("Admin", adminSchema);
