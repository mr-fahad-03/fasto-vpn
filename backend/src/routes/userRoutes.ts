import { Router } from "express";
import { getUserByIdController, listUsersController, updateUserStatusController } from "../controllers/userController";
import { authAdmin } from "../middlewares/authAdmin";
import { validate } from "../middlewares/validate";
import { asyncHandler } from "../utils/asyncHandler";
import { idParamSchema, userStatusSchema, usersListQuerySchema } from "../utils/schemas";

export const userRoutes = Router();

userRoutes.use("/admin", authAdmin);
userRoutes.get("/admin/users", validate(usersListQuerySchema, "query"), asyncHandler(listUsersController));
userRoutes.get("/admin/users/:id", validate(idParamSchema, "params"), asyncHandler(getUserByIdController));
userRoutes.patch(
  "/admin/users/:id/status",
  validate(idParamSchema, "params"),
  validate(userStatusSchema),
  asyncHandler(updateUserStatusController),
);
