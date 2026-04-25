import { env } from "./env";

export const PLAN_METADATA = {
  free: {
    code: "free",
    adsEnabled: true,
    proxyLimit: env.FREE_PROXY_LIMIT,
  },
  premium: {
    code: "premium",
    adsEnabled: false,
    proxyLimit: null,
    priceUsd: env.PREMIUM_PLAN_PRICE_USD,
    currency: "USD",
  },
} as const;

export type PlanCode = keyof typeof PLAN_METADATA;
