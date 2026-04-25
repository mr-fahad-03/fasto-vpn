import dotenv from "dotenv";
import { z } from "zod";

dotenv.config();

const envSchema = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
  PORT: z.coerce.number().int().positive().default(4000),
  API_PREFIX: z.string().default("/api/v1"),
  MONGODB_URI: z.string().min(1),
  CORS_ORIGIN: z.string().default("*"),

  JWT_ACCESS_SECRET: z.string().min(16),
  JWT_REFRESH_SECRET: z.string().min(16),
  JWT_ACCESS_TTL: z.string().default("15m"),
  JWT_REFRESH_TTL: z.string().default("30d"),
  BCRYPT_SALT_ROUNDS: z.coerce.number().int().min(8).max(16).default(12),

  ADMIN_DEFAULT_EMAIL: z.string().email().default("admin@fastovpn.com"),
  ADMIN_DEFAULT_PASSWORD: z.string().min(8).default("Admin@12345"),

  FREE_PROXY_LIMIT: z.coerce.number().int().min(1).default(20),
  PREMIUM_PLAN_PRICE_USD: z.coerce.number().positive().default(9.99),

  REVENUECAT_WEBHOOK_SECRET: z.string().min(8),

  FIREBASE_PROJECT_ID: z.string().optional(),
  FIREBASE_CLIENT_EMAIL: z.string().optional(),
  FIREBASE_PRIVATE_KEY: z.string().optional(),
  FIREBASE_SKIP_VERIFY: z
    .string()
    .optional()
    .transform((value) => value === "true"),

  GEO_LOOKUP_URL: z.string().url().default("https://ipwho.is"),
});

const parsed = envSchema.safeParse(process.env);
if (!parsed.success) {
  const issues = parsed.error.issues.map((issue) => `${issue.path.join(".")}: ${issue.message}`).join("; ");
  throw new Error(`Invalid environment configuration: ${issues}`);
}

export const env = parsed.data;
