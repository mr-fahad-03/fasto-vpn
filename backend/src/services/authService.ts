import bcrypt from "bcryptjs";
import { env } from "../config/env";
import { ApiError } from "../utils/ApiError";
import {
  AdminTokenPayload,
  signAdminAccessToken,
  signAdminRefreshToken,
  verifyAdminRefreshToken,
} from "../utils/jwt";
import { AdminModel } from "../models/Admin";

export async function adminLogin(params: {
  email: string;
  password: string;
}): Promise<{
  accessToken: string;
  refreshToken: string;
  admin: { id: string; email: string; role: string };
}> {
  const admin = await AdminModel.findOne({ email: params.email.toLowerCase().trim() });

  if (!admin || !admin.isActive) {
    throw new ApiError(401, "Invalid credentials");
  }

  const ok = await bcrypt.compare(params.password, admin.passwordHash);
  if (!ok) {
    throw new ApiError(401, "Invalid credentials");
  }

  admin.lastLoginAt = new Date();
  await admin.save();

  const payload: AdminTokenPayload = {
    sub: admin._id.toString(),
    email: admin.email,
    role: "admin",
    tokenVersion: admin.tokenVersion,
  };

  return {
    accessToken: signAdminAccessToken(payload),
    refreshToken: signAdminRefreshToken(payload),
    admin: {
      id: admin._id.toString(),
      email: admin.email,
      role: admin.role,
    },
  };
}

export async function adminRefresh(refreshToken: string): Promise<{ accessToken: string; refreshToken: string }> {
  let payload: AdminTokenPayload;
  try {
    payload = verifyAdminRefreshToken(refreshToken);
  } catch {
    throw new ApiError(401, "Invalid refresh token");
  }

  const admin = await AdminModel.findById(payload.sub);
  if (!admin || !admin.isActive) {
    throw new ApiError(401, "Admin session invalid");
  }

  if (admin.tokenVersion !== payload.tokenVersion) {
    throw new ApiError(401, "Refresh token revoked");
  }

  const nextPayload: AdminTokenPayload = {
    sub: admin._id.toString(),
    email: admin.email,
    role: "admin",
    tokenVersion: admin.tokenVersion,
  };

  return {
    accessToken: signAdminAccessToken(nextPayload),
    refreshToken: signAdminRefreshToken(nextPayload),
  };
}

export async function adminLogout(refreshToken: string): Promise<void> {
  try {
    const payload = verifyAdminRefreshToken(refreshToken);
    await AdminModel.findByIdAndUpdate(payload.sub, { $inc: { tokenVersion: 1 } });
  } catch {
    return;
  }
}

export async function ensureDefaultAdmin(): Promise<void> {
  const email = env.ADMIN_DEFAULT_EMAIL.toLowerCase().trim();
  const existing = await AdminModel.findOne({ email });
  if (existing) return;

  const passwordHash = await bcrypt.hash(env.ADMIN_DEFAULT_PASSWORD, env.BCRYPT_SALT_ROUNDS);
  await AdminModel.create({
    email,
    passwordHash,
    role: "admin",
    isActive: true,
  });
}
