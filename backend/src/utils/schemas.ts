import { z } from "zod";

const boolFromAny = z
  .union([z.boolean(), z.string()])
  .transform((value) => (typeof value === "boolean" ? value : value === "true"));

export const adminLoginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

export const adminRefreshSchema = z.object({
  refreshToken: z.string().min(20),
});

export const idParamSchema = z.object({
  id: z.string().min(8),
});

const proxyBaseObjectSchema = z.object({
  name: z.string().min(1),
  host: z.string().min(1),
  port: z.coerce.number().int().min(1).max(65535),
  type: z.enum(["HTTP", "SOCKS5"]).default("HTTP"),
  username: z.string().trim().min(1).max(160).optional(),
  password: z.string().trim().min(1).max(160).optional(),
  status: z.enum(["active", "inactive"]).default("active"),
  isPremium: boolFromAny.default(false),
  sortOrder: z.coerce.number().int().min(0).optional(),
  tags: z.array(z.string().min(1)).default([]),
  latency: z.coerce.number().int().min(0).default(0),
  healthStatus: z.enum(["unknown", "healthy", "degraded", "down"]).default("unknown"),
  maxFreeVisible: boolFromAny.default(true),
});

function validateProxyAuthPair(
  input: { username?: string; password?: string },
  ctx: z.RefinementCtx,
): void {
  const hasUsername = Boolean(input.username);
  const hasPassword = Boolean(input.password);

  if (hasUsername !== hasPassword) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      path: ["password"],
      message: "Username and password must be provided together",
    });
  }
}

export const createProxySchema = proxyBaseObjectSchema.superRefine(validateProxyAuthPair);
export const updateProxySchema = proxyBaseObjectSchema.partial().superRefine(validateProxyAuthPair);

export const proxyListQuerySchema = z.object({
  page: z.string().optional(),
  limit: z.string().optional(),
  search: z.string().optional(),
  status: z.enum(["active", "inactive"]).optional(),
  isPremium: z.string().optional(),
  countryCode: z.string().length(2).optional(),
  sortBy: z.string().optional(),
  sortOrder: z.enum(["asc", "desc"]).optional(),
});

export const updateProxyStatusSchema = z.object({
  status: z.enum(["active", "inactive"]),
});

export const reorderProxiesSchema = z.object({
  items: z.array(
    z.object({
      id: z.string().min(8),
      sortOrder: z.coerce.number().int().min(0),
    }),
  ),
});

export const bulkImportSchema = z.object({
  items: z.array(createProxySchema).optional(),
  rawText: z.string().optional(),
  defaults: proxyBaseObjectSchema.partial().superRefine(validateProxyAuthPair).optional(),
});

export const revenueCatWebhookSchema = z.object({
  event: z.object({
    id: z.string().optional(),
    type: z.string(),
    app_user_id: z.string().min(1),
    entitlement_ids: z.array(z.string()).optional(),
    product_id: z.string().optional(),
    expiration_at_ms: z.number().nullable().optional(),
    event_timestamp_ms: z.number().nullable().optional(),
  }),
});

export const dashboardRecentQuerySchema = z.object({
  limit: z.string().optional(),
});

export const usersListQuerySchema = z.object({
  page: z.string().optional(),
  limit: z.string().optional(),
  search: z.string().optional(),
  mode: z.enum(["guest", "mobile"]).optional(),
  isActive: z.enum(["true", "false"]).optional(),
  sortBy: z.string().optional(),
  sortOrder: z.enum(["asc", "desc"]).optional(),
});

export const userStatusSchema = z.object({
  isActive: z.boolean(),
});

export const subscriptionsListQuerySchema = z.object({
  page: z.string().optional(),
  limit: z.string().optional(),
  search: z.string().optional(),
  status: z.string().optional(),
  isPremium: z.enum(["true", "false"]).optional(),
  overrideActive: z.enum(["true", "false"]).optional(),
  sortBy: z.string().optional(),
  sortOrder: z.enum(["asc", "desc"]).optional(),
});

export const subscriptionOverrideSchema = z.object({
  plan: z.enum(["free", "premium"]),
  reason: z.string().max(500).optional(),
});

export const adminSettingsSchema = z.object({
  freePlanAdsEnabled: z.boolean(),
  maxFreeProxiesCount: z.coerce.number().int().min(1).max(500),
  featuredCountries: z.array(z.string().length(2).transform((value) => value.toUpperCase())),
  appNotices: z.array(z.string().min(1).max(300)),
});

export const mobileProxyConnectSchema = z.object({
  proxyId: z.string().min(8),
});
