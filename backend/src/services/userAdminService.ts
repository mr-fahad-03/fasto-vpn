import { FilterQuery } from "mongoose";
import { UserDoc, UserModel } from "../models/User";
import { ApiError } from "../utils/ApiError";
import { parsePagination } from "../utils/pagination";

function serializeUser(user: UserDoc) {
  return {
    id: user._id.toString(),
    mode: user.mode,
    firebaseUid: user.firebaseUid,
    email: user.email,
    displayName: user.displayName,
    guestSessionId: user.guestSessionId,
    isActive: user.isActive,
    lastSeenAt: user.lastSeenAt,
    createdAt: user.createdAt,
    updatedAt: user.updatedAt,
  };
}

export async function listUsersAdmin(params: {
  page?: string;
  limit?: string;
  search?: string;
  mode?: "guest" | "mobile";
  isActive?: string;
  sortBy?: string;
  sortOrder?: "asc" | "desc";
}) {
  const { page, limit, skip } = parsePagination(params.page, params.limit);
  const filter: FilterQuery<UserDoc> = {};

  if (params.mode) {
    filter.mode = params.mode;
  }

  if (params.isActive === "true") {
    filter.isActive = true;
  }

  if (params.isActive === "false") {
    filter.isActive = false;
  }

  if (params.search) {
    filter.$or = [
      { email: { $regex: params.search, $options: "i" } },
      { displayName: { $regex: params.search, $options: "i" } },
      { firebaseUid: { $regex: params.search, $options: "i" } },
      { guestSessionId: { $regex: params.search, $options: "i" } },
    ];
  }

  const allowedSortFields = new Set(["createdAt", "updatedAt", "lastSeenAt", "email", "mode"]);
  const sortField = allowedSortFields.has(params.sortBy ?? "") ? params.sortBy! : "createdAt";
  const sort: Record<string, 1 | -1> = { [sortField]: params.sortOrder === "asc" ? 1 : -1 };

  const [items, total] = await Promise.all([
    UserModel.find(filter).sort(sort).skip(skip).limit(limit),
    UserModel.countDocuments(filter),
  ]);

  return {
    items: items.map(serializeUser),
    page,
    limit,
    total,
    totalPages: Math.ceil(total / limit),
  };
}

export async function updateUserStatusAdmin(id: string, isActive: boolean) {
  const user = await UserModel.findByIdAndUpdate(id, { $set: { isActive } }, { new: true });
  if (!user) {
    throw new ApiError(404, "User not found");
  }
  return serializeUser(user);
}

export async function getUserByIdAdmin(id: string) {
  const user = await UserModel.findById(id);
  if (!user) {
    throw new ApiError(404, "User not found");
  }
  return serializeUser(user);
}
