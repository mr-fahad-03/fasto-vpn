import compression from "compression";
import cors from "cors";
import express from "express";
import rateLimit from "express-rate-limit";
import helmet from "helmet";
import morgan from "morgan";
import { env } from "./config/env";
import { logger } from "./config/logger";
import { errorHandler, notFoundHandler } from "./middlewares/errorHandler";
import { requestContext } from "./middlewares/requestContext";
import { healthRoutes } from "./routes/healthRoutes";
import { apiRoutes } from "./routes";

export const app = express();

app.disable("x-powered-by");
app.use(requestContext);
app.use(helmet());
app.use(
  cors({
    origin: env.CORS_ORIGIN === "*" ? true : env.CORS_ORIGIN,
    credentials: true,
  }),
);
app.use(compression());
app.use(
  rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 500,
    standardHeaders: true,
    legacyHeaders: false,
  }),
);

app.use(
  express.json({
    limit: "2mb",
    verify: (req, _res, buffer) => {
      (req as unknown as Express.Request).rawBody = buffer.toString("utf8");
    },
  }),
);

app.use(
  morgan("combined", {
    stream: {
      write: (message: string) => logger.info(message.trim()),
    },
  }),
);

app.use(healthRoutes);
app.use(env.API_PREFIX, apiRoutes);

app.use(notFoundHandler);
app.use(errorHandler);
