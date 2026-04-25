export type ApiEnvelope<T> = {
  success: boolean;
  message?: string;
  data: T;
};

export type Paginated<T> = {
  items: T[];
  page: number;
  limit: number;
  total: number;
  totalPages: number;
};

export type AdminProfile = {
  id: string;
  email: string;
  role: "admin";
};

export type DashboardStats = {
  proxyCountByCountry: Array<{ countryCode: string; count: number }>;
  activeVsInactive: { active: number; inactive: number };
  premiumVsFreeProxyCounts: { premium: number; free: number };
  userStats: { totalUsers: number; premiumUsers: number; guests: number };
};

export type ActivityItem = {
  id: string;
  eventType: string;
  metadata?: Record<string, unknown>;
  ip?: string;
  userAgent?: string;
  user?: { mode?: string; email?: string; firebaseUid?: string };
  createdAt: string;
};

export type ProxyItem = {
  id: string;
  name: string;
  host: string;
  ip?: string;
  port: number;
  username?: string;
  password?: string;
  type: "HTTP" | "SOCKS5";
  country: string;
  countryCode: string;
  city?: string;
  region?: string;
  isp?: string;
  status: "active" | "inactive";
  isPremium: boolean;
  sortOrder: number;
  tags: string[];
  latency: number;
  healthStatus: "unknown" | "healthy" | "degraded" | "down";
  maxFreeVisible: boolean;
  createdAt: string;
  updatedAt: string;
};

export type UserItem = {
  id: string;
  mode: "guest" | "mobile";
  firebaseUid?: string;
  email?: string;
  displayName?: string;
  guestSessionId?: string;
  isActive: boolean;
  lastSeenAt?: string;
  createdAt: string;
  updatedAt: string;
};

export type SubscriptionItem = {
  id: string;
  user?: {
    id?: string;
    mode?: "guest" | "mobile";
    email?: string;
    firebaseUid?: string;
    isActive?: boolean;
  };
  provider: "revenuecat";
  revenueCatAppUserId?: string;
  productId?: string;
  entitlementId: string;
  status: "free" | "premium" | "expired" | "cancelled";
  isPremium: boolean;
  adsEnabled: boolean;
  planPriceUsd: number;
  currency: string;
  expiresAt?: string;
  sourceEntitlementId?: string;
  sourceStatus?: string;
  sourceIsPremium?: boolean;
  sourceAdsEnabled?: boolean;
  manualOverride?: {
    isActive?: boolean;
    plan?: "free" | "premium";
    reason?: string;
    setAt?: string;
  };
  updatedAt: string;
};

export type AdminSettings = {
  freePlanAdsEnabled: boolean;
  maxFreeProxiesCount: number;
  featuredCountries: string[];
  appNotices: string[];
};
