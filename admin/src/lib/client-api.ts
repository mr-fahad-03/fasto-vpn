import type {
  ActivityItem,
  AdminSettings,
  DashboardStats,
  Paginated,
  ProxyItem,
  SubscriptionItem,
  UserItem,
} from "./types";

let isHandlingAuthFailure = false;

function toQuery(params: Record<string, string | number | boolean | undefined>): string {
  const qs = new URLSearchParams();
  Object.entries(params).forEach(([key, value]) => {
    if (value !== undefined && value !== "") {
      qs.set(key, String(value));
    }
  });
  const value = qs.toString();
  return value ? `?${value}` : "";
}

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await fetch(path, {
    ...init,
    headers: {
      "Content-Type": "application/json",
      ...(init?.headers ?? {}),
    },
    cache: "no-store",
  });

  if (response.status === 401 || response.status === 403) {
    if (!isHandlingAuthFailure) {
      isHandlingAuthFailure = true;
      await fetch("/api/auth/logout", { method: "POST" });
      if (typeof window !== "undefined") {
        window.location.href = "/login";
      }
    }
    throw new Error("Session expired");
  }

  const payload = await response.json();
  if (!response.ok || payload.success === false) {
    throw new Error(payload.message ?? "Request failed");
  }

  return payload.data as T;
}

export const api = {
  login: (email: string, password: string) =>
    request<{ admin: { id: string; email: string; role: string } }>("/api/auth/login", {
      method: "POST",
      body: JSON.stringify({ email, password }),
    }),

  logout: () => request<void>("/api/auth/logout", { method: "POST" }),

  getDashboardStats: () => request<DashboardStats>("/api/admin/dashboard/stats"),
  getRecentActivity: (limit = 20) => request<ActivityItem[]>(`/api/admin/dashboard/recent-activity?limit=${limit}`),

  listProxies: (params: Record<string, string | number | boolean | undefined>) =>
    request<Paginated<ProxyItem>>(`/api/admin/proxies${toQuery(params)}`),
  getProxy: (id: string) => request<ProxyItem>(`/api/admin/proxies/${id}`),
  createProxy: (payload: Record<string, unknown>) =>
    request<ProxyItem>("/api/admin/proxies", {
      method: "POST",
      body: JSON.stringify(payload),
    }),
  updateProxy: (id: string, payload: Record<string, unknown>) =>
    request<ProxyItem>(`/api/admin/proxies/${id}`, {
      method: "PATCH",
      body: JSON.stringify(payload),
    }),
  deleteProxy: (id: string) =>
    request<void>(`/api/admin/proxies/${id}`, {
      method: "DELETE",
    }),
  updateProxyStatus: (id: string, status: "active" | "inactive") =>
    request<ProxyItem>(`/api/admin/proxies/${id}/status`, {
      method: "PATCH",
      body: JSON.stringify({ status }),
    }),
  reorderProxies: (items: Array<{ id: string; sortOrder: number }>) =>
    request<void>("/api/admin/proxies/reorder", {
      method: "POST",
      body: JSON.stringify({ items }),
    }),
  bulkImportProxies: (rawText: string, isPremium: boolean) =>
    request<{ imported: number; items: ProxyItem[] }>("/api/admin/proxies/bulk-import", {
      method: "POST",
      body: JSON.stringify({ rawText, defaults: { isPremium } }),
    }),

  listUsers: (params: Record<string, string | number | boolean | undefined>) =>
    request<Paginated<UserItem>>(`/api/admin/users${toQuery(params)}`),
  updateUserStatus: (id: string, isActive: boolean) =>
    request<UserItem>(`/api/admin/users/${id}/status`, {
      method: "PATCH",
      body: JSON.stringify({ isActive }),
    }),

  listSubscriptions: (params: Record<string, string | number | boolean | undefined>) =>
    request<Paginated<SubscriptionItem>>(`/api/admin/subscriptions${toQuery(params)}`),
  setSubscriptionOverride: (id: string, plan: "free" | "premium", reason?: string) =>
    request<SubscriptionItem>(`/api/admin/subscriptions/${id}/override`, {
      method: "PATCH",
      body: JSON.stringify({ plan, reason }),
    }),
  clearSubscriptionOverride: (id: string) =>
    request<SubscriptionItem>(`/api/admin/subscriptions/${id}/override`, {
      method: "DELETE",
    }),

  getSettings: () => request<AdminSettings>("/api/admin/settings"),
  updateSettings: (payload: AdminSettings) =>
    request<AdminSettings>("/api/admin/settings", {
      method: "PUT",
      body: JSON.stringify(payload),
    }),
};
