import { z } from "zod";

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

export const proxyFormSchema = z.object({
  name: z.string().min(1),
  host: z.string().min(1),
  port: z.coerce.number().int().min(1).max(65535),
  type: z.enum(["HTTP", "SOCKS5"]),
  username: z.string().optional(),
  password: z.string().optional(),
  isPremium: z.boolean(),
  status: z.enum(["active", "inactive"]),
  sortOrder: z.coerce.number().int().min(0),
  tags: z.string(),
  maxFreeVisible: z.boolean(),
  latency: z.coerce.number().int().min(0),
  healthStatus: z.enum(["unknown", "healthy", "degraded", "down"]),
}).superRefine((input, ctx) => {
  const hasUsername = Boolean(input.username?.trim());
  const hasPassword = Boolean(input.password?.trim());

  if (hasUsername !== hasPassword) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      path: ["password"],
      message: "Username and password must be provided together",
    });
  }
});

export const bulkImportSchema = z.object({
  rawText: z.string().min(10),
  isPremium: z.boolean().default(false),
});

export const settingsSchema = z.object({
  freePlanAdsEnabled: z.boolean(),
  maxFreeProxiesCount: z.coerce.number().int().min(1).max(500),
  featuredCountries: z.string(),
  appNotices: z.string(),
});

export const subscriptionOverrideSchema = z.object({
  plan: z.enum(["free", "premium"]),
  reason: z.string().max(500).optional(),
});

export type LoginInput = z.infer<typeof loginSchema>;
export type ProxyFormInput = z.infer<typeof proxyFormSchema>;
export type BulkImportInput = z.infer<typeof bulkImportSchema>;
export type SettingsInput = z.infer<typeof settingsSchema>;
