import { ApiError } from "../../utils/ApiError";
import { resolveHostToIp } from "../../utils/dns";
import {
  applyGeoFallback,
  GEO_UNKNOWN_COUNTRY,
  GEO_UNKNOWN_COUNTRY_CODE,
  isIpAddress,
  isPrivateIpv4,
  normalizeHostInput,
  normalizeNameInput,
  normalizeProxyCredential,
  normalizeTags,
  preserveGeoOnLookupFailure,
  RESOLVED_IP_UNKNOWN,
  unknownGeoFields,
  validateProxyFields,
} from "./helpers";
import {
  createDefaultGeoLookupProvider,
  GeoLookupProvider,
  GeoLookupStatus,
} from "./provider";
import { SupportedProxyType } from "../../utils/proxy";

export type ProxyNormalizationInput = {
  name: string;
  host: string;
  port: number;
  username?: string;
  password?: string;
  type?: SupportedProxyType;
  status?: "active" | "inactive";
  isPremium?: boolean;
  sortOrder?: number;
  tags?: string[];
  latency?: number;
  healthStatus?: "unknown" | "healthy" | "degraded" | "down";
  maxFreeVisible?: boolean;
};

export type ExistingProxyGeoContext = {
  host?: string;
  ip?: string;
  country?: string;
  countryCode?: string;
  region?: string;
  city?: string;
  timezone?: string;
  isp?: string;
  asn?: string;
  geoLookupRaw?: Record<string, unknown>;
  geoLookupProvider?: string;
  geoLookupStatus?: GeoLookupStatus;
  geoLookupError?: string;
};

export type NormalizedProxyOutput = {
  name: string;
  host: string;
  resolvedIp: string;
  port: number;
  username?: string;
  password?: string;
  type: SupportedProxyType;
  status: "active" | "inactive";
  isPremium: boolean;
  sortOrder: number;
  tags: string[];
  latency: number;
  healthStatus: "unknown" | "healthy" | "degraded" | "down";
  maxFreeVisible: boolean;

  country: string;
  countryCode: string;
  region?: string;
  city?: string;
  timezone?: string;
  isp?: string;
  asn?: string;

  geoLookupRaw: Record<string, unknown>;
  geoLookupProvider: string;
  geoLookupStatus: GeoLookupStatus;
  geoLookupError?: string;
};

export type NormalizeProxyInputOptions = {
  existing?: ExistingProxyGeoContext;
  geoProvider?: GeoLookupProvider;
  dnsResolver?: (hostOrIp: string) => Promise<string>;
};

function normalizeAsnValue(value: string | undefined): string | undefined {
  if (!value) {
    return undefined;
  }

  const trimmed = value.trim();
  return trimmed || undefined;
}

export async function normalizeProxyInput(
  input: ProxyNormalizationInput,
  options: NormalizeProxyInputOptions = {},
): Promise<NormalizedProxyOutput> {
  const geoProvider = options.geoProvider ?? createDefaultGeoLookupProvider();
  const dnsResolver = options.dnsResolver ?? resolveHostToIp;

  const name = normalizeNameInput(input.name);
  const host = normalizeHostInput(input.host);
  const username = input.username ? normalizeProxyCredential(input.username) : undefined;
  const password = input.password ? normalizeProxyCredential(input.password) : undefined;
  const type: SupportedProxyType = input.type ?? "HTTP";
  const tags = normalizeTags(input.tags ?? []);

  if (!name) {
    throw new ApiError(400, "Proxy name is required");
  }

  if (!host) {
    throw new ApiError(400, "Proxy host is required");
  }

  if (isIpAddress(host) && isPrivateIpv4(host)) {
    throw new ApiError(400, "Private or loopback IP addresses are not allowed for proxy host");
  }

  const proxyIssues = validateProxyFields({
    port: input.port,
    type,
    username,
    password,
  });

  if (proxyIssues.length > 0) {
    throw new ApiError(400, "Invalid proxy payload", {
      issues: proxyIssues,
    });
  }

  const existing = options.existing;
  const existingHost = existing?.host ? normalizeHostInput(existing.host) : undefined;
  const hostChanged = !existing || existingHost !== host;

  let resolvedIp: string | undefined;
  let lookupStatus: GeoLookupStatus = "fallback";
  let lookupError: string | undefined;
  let geoLookupRaw: Record<string, unknown> = {};
  let geoLookupProviderName = geoProvider.providerName;

  if (isIpAddress(host)) {
    resolvedIp = host;
  } else {
    try {
      const dnsResolved = await dnsResolver(host);
      if (isIpAddress(dnsResolved)) {
        resolvedIp = dnsResolved;
      } else {
        lookupError = "DNS resolver did not return a valid IP";
      }
    } catch (error) {
      lookupError = error instanceof Error ? error.message : "DNS resolution failed";
    }
  }

  let selectedGeo = unknownGeoFields();
  let selectedTimezone: string | undefined;
  let selectedIsp: string | undefined;
  let selectedAsn: string | undefined;

  if (!hostChanged && existing) {
    selectedGeo = applyGeoFallback({
      country: existing.country,
      countryCode: existing.countryCode,
      region: existing.region,
      city: existing.city,
      timezone: existing.timezone,
      isp: existing.isp,
      asn: existing.asn,
    });
    selectedTimezone = selectedGeo.timezone;
    selectedIsp = selectedGeo.isp;
    selectedAsn = normalizeAsnValue(selectedGeo.asn);
    lookupStatus = existing.geoLookupStatus ?? "success";
    lookupError = existing.geoLookupError;
    geoLookupRaw = existing.geoLookupRaw ?? { reused: true };
    geoLookupProviderName = existing.geoLookupProvider ?? geoProvider.providerName;
  } else {
    const lookupIp = resolvedIp ?? existing?.ip;

    if (lookupIp && isIpAddress(lookupIp) && !isPrivateIpv4(lookupIp)) {
      const providerResult = await geoProvider.lookup(lookupIp);
      geoLookupRaw = providerResult.raw;

      if (providerResult.success && providerResult.geo) {
        selectedGeo = applyGeoFallback(providerResult.geo);
        selectedTimezone = selectedGeo.timezone;
        selectedIsp = selectedGeo.isp;
        selectedAsn = normalizeAsnValue(selectedGeo.asn);
        lookupStatus = "success";
        lookupError = undefined;
      } else {
        const preserved = preserveGeoOnLookupFailure(existing);

        if (preserved) {
          selectedGeo = preserved;
          selectedTimezone = preserved.timezone;
          selectedIsp = preserved.isp;
          selectedAsn = normalizeAsnValue(preserved.asn);
          lookupStatus = "failed";
        } else {
          selectedGeo = unknownGeoFields();
          lookupStatus = "fallback";
        }

        lookupError = providerResult.error ?? lookupError ?? "Geo lookup failed";
      }
    } else {
      const preserved = preserveGeoOnLookupFailure(existing);

      if (preserved) {
        selectedGeo = preserved;
        selectedTimezone = preserved.timezone;
        selectedIsp = preserved.isp;
        selectedAsn = normalizeAsnValue(preserved.asn);
        lookupStatus = "failed";
      } else {
        selectedGeo = unknownGeoFields();
        lookupStatus = "fallback";
      }

      if (!lookupError) {
        if (!lookupIp) {
          lookupError = "No IP available for lookup";
        } else if (isPrivateIpv4(lookupIp)) {
          lookupError = "Private IP is not supported by geo lookup";
        } else {
          lookupError = "Invalid IP for geo lookup";
        }
      }

      geoLookupRaw = {
        ...geoLookupRaw,
        dnsError: lookupError,
        resolvedIp,
        lookupIp,
      };
    }
  }

  return {
    name,
    host,
    resolvedIp: resolvedIp ?? existing?.ip ?? RESOLVED_IP_UNKNOWN,
    port: input.port,
    username: username || undefined,
    password: password || undefined,
    type,
    status: input.status ?? "active",
    isPremium: input.isPremium ?? false,
    sortOrder: input.sortOrder ?? 0,
    tags,
    latency: input.latency ?? 0,
    healthStatus: input.healthStatus ?? "unknown",
    maxFreeVisible: input.maxFreeVisible ?? true,

    country: selectedGeo.country || GEO_UNKNOWN_COUNTRY,
    countryCode: selectedGeo.countryCode || GEO_UNKNOWN_COUNTRY_CODE,
    region: selectedGeo.region,
    city: selectedGeo.city,
    timezone: selectedTimezone,
    isp: selectedIsp,
    asn: selectedAsn,

    geoLookupRaw,
    geoLookupProvider: geoLookupProviderName,
    geoLookupStatus: lookupStatus,
    geoLookupError: lookupStatus === "success" ? undefined : lookupError,
  };
}
