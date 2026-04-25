import { Router } from "express";
import { authRoutes } from "./authRoutes";
import { dashboardRoutes } from "./dashboardRoutes";
import { mobileRoutes } from "./mobileRoutes";
import { proxyRoutes } from "./proxyRoutes";
import { settingsRoutes } from "./settingsRoutes";
import { subscriptionRoutes } from "./subscriptionRoutes";
import { userRoutes } from "./userRoutes";
import { webhookRoutes } from "./webhookRoutes";

export const apiRoutes = Router();

apiRoutes.use(authRoutes);
apiRoutes.use(proxyRoutes);
apiRoutes.use(mobileRoutes);
apiRoutes.use(webhookRoutes);
apiRoutes.use(dashboardRoutes);
apiRoutes.use(userRoutes);
apiRoutes.use(subscriptionRoutes);
apiRoutes.use(settingsRoutes);
