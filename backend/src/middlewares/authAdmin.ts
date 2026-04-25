import { NextFunction, Request, Response } from "express";
import { verifyAdminAccessToken } from "../utils/jwt";
import { ApiError } from "../utils/ApiError";
import { AdminModel } from "../models/Admin";

export async function authAdmin(req: Request, _res: Response, next: NextFunction): Promise<void> {
  const authHeader = req.header("authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return next(new ApiError(401, "Missing admin token"));
  }

  const token = authHeader.replace("Bearer ", "").trim();

  try {
    const payload = verifyAdminAccessToken(token);
    const admin = await AdminModel.findById(payload.sub).lean();

    if (!admin || !admin.isActive || admin.tokenVersion !== payload.tokenVersion) {
      return next(new ApiError(401, "Invalid admin session"));
    }

    req.admin = {
      id: payload.sub,
      email: payload.email,
      role: "admin",
      tokenVersion: payload.tokenVersion,
    };

    return next();
  } catch (error) {
    if (error instanceof ApiError) {
      return next(error);
    }

    return next(new ApiError(401, "Invalid or expired admin token"));
  }
}
