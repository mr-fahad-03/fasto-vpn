import { Router } from "express";
import { healthController } from "../controllers/healthController";

export const healthRoutes = Router();

healthRoutes.get("/health", healthController);
