import { FilterQuery } from "mongoose";
import { env } from "../config/env";
import { PLAN_METADATA } from "../config/plans";
import { ProxyDoc, ProxyModel } from "../models/Proxy";
import {
  normalizeProxyInput,
  ProxyNormalizationInput,
} from "./proxyNormalization/service";
import { ApiError } from "../utils/ApiError";
import { normalizeProxyType, parseProxyBulkText } from "../utils/proxy";
import { parsePagination } from "../utils/pagination";
import { getFreePlanRuntimeConfig } from "./settingsService";

type ProxyUpsertInput = ProxyNormalizationInput;

function serializeProxy(doc: ProxyDoc) {
  return {
    id: doc._id.toString(),
    name: doc.name,
    host: doc.host,
    ip: doc.ip,
    port: doc.port,
    username: doc.username,
    password: doc.password,
    type: normalizeProxyType(doc.type) ?? "HTTP",
    country: doc.country,
    countryCode: doc.countryCode,
    city: doc.city,
    region: doc.region,
    timezone: doc.timezone,
    isp: doc.isp,
    asn: doc.asn,
    geoLookupRaw: doc.geoLookupRaw,
    geoLookupProvider: doc.geoLookupProvider,
    geoLookupStatus: doc.geoLookupStatus,
    geoLookupError: doc.geoLookupError,
    status: doc.status,
    isPremium: doc.isPremium,
    sortOrder: doc.sortOrder,
    tags: doc.tags,
    latency: doc.latency,
    healthStatus: doc.healthStatus,
    maxFreeVisible: doc.maxFreeVisible,
    createdAt: doc.createdAt,
    updatedAt: doc.updatedAt,
  };
}

function mapNormalizedToProxyDoc(
  normalized: Awaited<ReturnType<typeof normalizeProxyInput>>,
): Partial<ProxyDoc> {
  return {
    name: normalized.name,
    host: normalized.host,
    ip: normalized.resolvedIp === "Unknown" ? undefined : normalized.resolvedIp,
    port: normalized.port,
    username: normalized.username,
    password: normalized.password,
    type: normalized.type,
    country: normalized.country,
    countryCode: normalized.countryCode,
    city: normalized.city,
    region: normalized.region,
    timezone: normalized.timezone,
    isp: normalized.isp,
    asn: normalized.asn,
    geoLookupRaw: normalized.geoLookupRaw,
    geoLookupProvider: normalized.geoLookupProvider,
    geoLookupStatus: normalized.geoLookupStatus,
    geoLookupError: normalized.geoLookupError,
    status: normalized.status,
    isPremium: normalized.isPremium,
    sortOrder: normalized.sortOrder,
    tags: normalized.tags,
    latency: normalized.latency,
    healthStatus: normalized.healthStatus,
    maxFreeVisible: normalized.maxFreeVisible,
  };
}

export async function createProxy(input: ProxyUpsertInput, adminId: string) {
  const normalized = await normalizeProxyInput(input);
  const mapped = mapNormalizedToProxyDoc(normalized);

  if (!mapped.sortOrder) {
    const highest = await ProxyModel.findOne().sort({ sortOrder: -1 }).lean();
    mapped.sortOrder = (highest?.sortOrder ?? 0) + 1;
  }

  const created = await ProxyModel.create({
    ...mapped,
    createdBy: adminId,
    updatedBy: adminId,
  });

  return serializeProxy(created);
}

export async function updateProxy(id: string, input: Partial<ProxyUpsertInput>, adminId: string) {
  const existing = await ProxyModel.findById(id);
  if (!existing) {
    throw new ApiError(404, "Proxy not found");
  }

  const merged: ProxyUpsertInput = {
    name: input.name ?? existing.name,
    host: input.host ?? existing.host,
    port: input.port ?? existing.port,
    username: input.username ?? existing.username ?? undefined,
    password: input.password ?? existing.password ?? undefined,
    type: input.type ?? normalizeProxyType(existing.type) ?? "HTTP",
    status: input.status ?? existing.status,
    isPremium: input.isPremium ?? existing.isPremium,
    sortOrder: input.sortOrder ?? existing.sortOrder,
    tags: input.tags ?? existing.tags,
    latency: input.latency ?? existing.latency,
    healthStatus: input.healthStatus ?? existing.healthStatus,
    maxFreeVisible: input.maxFreeVisible ?? existing.maxFreeVisible,
  };

  const normalized = await normalizeProxyInput(merged, {
    existing: {
      host: existing.host,
      ip: existing.ip ?? undefined,
      country: existing.country ?? undefined,
      countryCode: existing.countryCode ?? undefined,
      region: existing.region ?? undefined,
      city: existing.city ?? undefined,
      timezone: existing.timezone ?? undefined,
      isp: existing.isp ?? undefined,
      asn: existing.asn ?? undefined,
      geoLookupRaw: existing.geoLookupRaw,
      geoLookupProvider: existing.geoLookupProvider ?? undefined,
      geoLookupStatus: existing.geoLookupStatus,
      geoLookupError: existing.geoLookupError ?? undefined,
    },
  });

  existing.set({
    ...mapNormalizedToProxyDoc(normalized),
    updatedBy: adminId,
  });
  await existing.save();

  return serializeProxy(existing);
}

export async function deleteProxy(id: string): Promise<void> {
  const deleted = await ProxyModel.findByIdAndDelete(id);
  if (!deleted) {
    throw new ApiError(404, "Proxy not found");
  }
}

export async function getProxyById(id: string) {
  const row = await ProxyModel.findById(id);
  if (!row) {
    throw new ApiError(404, "Proxy not found");
  }
  return serializeProxy(row);
}

export async function listAdminProxies(params: {
  page?: string;
  limit?: string;
  search?: string;
  status?: "active" | "inactive";
  isPremium?: string;
  countryCode?: string;
  sortBy?: string;
  sortOrder?: "asc" | "desc";
}) {
  const { page, limit, skip } = parsePagination(params.page, params.limit);

  const filter: FilterQuery<ProxyDoc> = {};

  if (params.search) {
    filter.$text = { $search: params.search };
  }

  if (params.status) {
    filter.status = params.status;
  }

  if (params.isPremium === "true") {
    filter.isPremium = true;
  }

  if (params.isPremium === "false") {
    filter.isPremium = false;
  }

  if (params.countryCode) {
    filter.countryCode = params.countryCode.toUpperCase();
  }

  const allowedSortFields = new Set([
    "createdAt",
    "updatedAt",
    "name",
    "country",
    "latency",
    "sortOrder",
  ]);

  const sortField = allowedSortFields.has(params.sortBy ?? "") ? params.sortBy! : "sortOrder";
  const sort: Record<string, 1 | -1> = { [sortField]: params.sortOrder === "desc" ? -1 : 1 };

  const [items, total] = await Promise.all([
    ProxyModel.find(filter).sort(sort).skip(skip).limit(limit),
    ProxyModel.countDocuments(filter),
  ]);

  return {
    items: items.map(serializeProxy),
    page,
    limit,
    total,
    totalPages: Math.ceil(total / limit),
  };
}

export async function updateProxyStatus(id: string, status: "active" | "inactive") {
  const updated = await ProxyModel.findByIdAndUpdate(id, { $set: { status } }, { new: true });
  if (!updated) {
    throw new ApiError(404, "Proxy not found");
  }
  return serializeProxy(updated);
}

export async function reorderProxies(items: Array<{ id: string; sortOrder: number }>): Promise<void> {
  if (!items.length) return;

  await ProxyModel.bulkWrite(
    items.map((item) => ({
      updateOne: {
        filter: { _id: item.id },
        update: { $set: { sortOrder: item.sortOrder } },
      },
    })),
  );
}

export async function bulkImportProxies(params: {
  items?: ProxyUpsertInput[];
  rawText?: string;
  defaults?: Partial<ProxyUpsertInput>;
  adminId: string;
}) {
  const preparedItems: ProxyUpsertInput[] = [];

  if (params.items?.length) {
    preparedItems.push(...params.items);
  }

  if (params.rawText) {
    const parsed = parseProxyBulkText(params.rawText);
    for (const item of parsed) {
      preparedItems.push({
        name: `Proxy ${item.host}:${item.port}`,
        host: item.host,
        port: item.port,
        type: item.type ?? params.defaults?.type ?? "HTTP",
        username: params.defaults?.username,
        password: params.defaults?.password,
        status: "active",
        isPremium: params.defaults?.isPremium ?? false,
        sortOrder: params.defaults?.sortOrder,
        tags: params.defaults?.tags ?? [],
        latency: params.defaults?.latency ?? 0,
        healthStatus: params.defaults?.healthStatus ?? "unknown",
        maxFreeVisible: params.defaults?.maxFreeVisible ?? true,
      });
    }
  }

  if (!preparedItems.length) {
    throw new ApiError(400, "No proxies found for import");
  }

  const created = [];
  for (const item of preparedItems) {
    const row = await createProxy(item, params.adminId);
    created.push(row);
  }

  return {
    imported: created.length,
    items: created,
  };
}

export async function listMobileProxies(params: {
  hasPremium: boolean;
  limitOverride?: number | null;
}) {
  const filter: FilterQuery<ProxyDoc> = { status: "active" };
  const limit = params.limitOverride ?? 500;

  const rows = await ProxyModel.find(filter).sort({ sortOrder: 1 }).limit(limit);

  return rows.map((row) => ({
    id: row._id.toString(),
    country: row.country,
    countryCode: row.countryCode,
    isPremium: row.isPremium,
    connect: {
      host: row.host,
      port: row.port,
      type: normalizeProxyType(row.type) ?? "HTTP",
      username: row.username,
      password: row.password,
    },
  }));
}

export async function connectMobileProxy(params: {
  proxyId: string;
  hasPremium: boolean;
}) {
  const row = await ProxyModel.findById(params.proxyId);
  if (!row || row.status !== "active") {
    throw new ApiError(404, "Selected server is not available");
  }

  if (!params.hasPremium && (row.isPremium || !row.maxFreeVisible)) {
    throw new ApiError(403, "Selected server requires Premium access");
  }

  return {
    id: row._id.toString(),
    country: row.country,
    countryCode: row.countryCode,
    connect: {
      host: row.host,
      port: row.port,
      type: normalizeProxyType(row.type) ?? "HTTP",
      username: row.username,
      password: row.password,
    },
  };
}

export async function getPlanMetadataSummary() {
  const freeConfig = await getFreePlanRuntimeConfig();
  return {
    free: {
      adsEnabled: freeConfig.adsEnabled,
      proxyLimit: freeConfig.maxFreeProxiesCount,
    },
    premium: {
      adsEnabled: PLAN_METADATA.premium.adsEnabled,
      proxyLimit: PLAN_METADATA.premium.proxyLimit,
      priceUsd: PLAN_METADATA.premium.priceUsd,
      currency: PLAN_METADATA.premium.currency,
    },
  };
}
