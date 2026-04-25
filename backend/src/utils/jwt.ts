import jwt from "jsonwebtoken";
import { env } from "../config/env";

export type AdminTokenPayload = {
  sub: string;
  email: string;
  role: "admin";
  tokenVersion: number;
};

export function signAdminAccessToken(payload: AdminTokenPayload): string {
  return jwt.sign(payload, env.JWT_ACCESS_SECRET, {
    expiresIn: env.JWT_ACCESS_TTL as jwt.SignOptions["expiresIn"],
  });
}

export function signAdminRefreshToken(payload: AdminTokenPayload): string {
  return jwt.sign(payload, env.JWT_REFRESH_SECRET, {
    expiresIn: env.JWT_REFRESH_TTL as jwt.SignOptions["expiresIn"],
  });
}

export function verifyAdminAccessToken(token: string): AdminTokenPayload {
  return jwt.verify(token, env.JWT_ACCESS_SECRET) as AdminTokenPayload;
}

export function verifyAdminRefreshToken(token: string): AdminTokenPayload {
  return jwt.verify(token, env.JWT_REFRESH_SECRET) as AdminTokenPayload;
}
