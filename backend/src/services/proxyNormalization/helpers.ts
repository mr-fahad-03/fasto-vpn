import net from "net";
import { isSupportedProxyType } from "../../utils/proxy";

export const GEO_UNKNOWN_COUNTRY = "Unknown";
export const GEO_UNKNOWN_COUNTRY_CODE = "XX";
export const RESOLVED_IP_UNKNOWN = "Unknown";

export type ProxyGeoFields = {
  country: string;
  countryCode: string;
  region?: string;
  city?: string;
  timezone?: string;
  isp?: string;
  asn?: string;
};

export type ProxyValidationInput = {
  port: number;
  type?: string;
  username?: string;
  password?: string;
};

export function sanitizeText(input: string, maxLength = 160): string {
  return input
    .normalize("NFKC")
    .replace(/[\x00-\x1F\x7F]/g, "")
    .trim()
    .slice(0, maxLength);
}

export function normalizeHostInput(host: string): string {
  return sanitizeText(host, 255).toLowerCase();
}

export function normalizeNameInput(name: string): string {
  return sanitizeText(name, 120);
}

export function normalizeProxyCredential(value: string): string {
  return sanitizeText(value, 160);
}

export function isIpAddress(value: string): boolean {
  return net.isIP(value.trim()) > 0;
}

export function isPrivateIpv4(ip: string): boolean {
  if (!isIpAddress(ip) || net.isIPv6(ip)) {
    return false;
  }

  const octets = ip.split(".").map((part) => Number(part));
  if (octets.length !== 4 || octets.some((part) => !Number.isInteger(part) || part < 0 || part > 255)) {
    return false;
  }

  const [a, b] = octets;

  if (a === 10 || a === 127) {
    return true;
  }

  if (a === 192 && b === 168) {
    return true;
  }

  // RFC1918 private block: 172.16.0.0/12
  if (a === 172 && b >= 16 && b <= 31) {
    return true;
  }

  return ip === "0.0.0.0";
}

export function normalizeTags(tags: string[]): string[] {
  const result = new Set<string>();

  for (const tag of tags) {
    const normalized = sanitizeText(tag, 40).toLowerCase();
    if (!normalized) {
      continue;
    }
    result.add(normalized);
  }

  return Array.from(result);
}

export function validateProxyFields(input: ProxyValidationInput): string[] {
  const issues: string[] = [];

  if (!Number.isInteger(input.port) || input.port < 1 || input.port > 65535) {
    issues.push("Port must be an integer between 1 and 65535");
  }

  if (input.type && !isSupportedProxyType(input.type)) {
    issues.push("Unsupported proxy type. Only HTTP and SOCKS5 are allowed");
  }

  const hasUsername = Boolean(input.username && input.username.trim());
  const hasPassword = Boolean(input.password && input.password.trim());

  if (hasUsername !== hasPassword) {
    issues.push("Username and password must be provided together");
  }

  return issues;
}

export function unknownGeoFields(): ProxyGeoFields {
  return {
    country: GEO_UNKNOWN_COUNTRY,
    countryCode: GEO_UNKNOWN_COUNTRY_CODE,
  };
}

export function applyGeoFallback(geo: Partial<ProxyGeoFields> | undefined): ProxyGeoFields {
  const cleanedCountry = geo?.country ? sanitizeText(geo.country, 80) : "";
  const cleanedCountryCode = geo?.countryCode
    ? sanitizeText(geo.countryCode, 2).toUpperCase()
    : GEO_UNKNOWN_COUNTRY_CODE;

  return {
    country: cleanedCountry || GEO_UNKNOWN_COUNTRY,
    countryCode: cleanedCountryCode.length === 2 ? cleanedCountryCode : GEO_UNKNOWN_COUNTRY_CODE,
    region: geo?.region ? sanitizeText(geo.region, 80) : undefined,
    city: geo?.city ? sanitizeText(geo.city, 80) : undefined,
    timezone: geo?.timezone ? sanitizeText(geo.timezone, 80) : undefined,
    isp: geo?.isp ? sanitizeText(geo.isp, 160) : undefined,
    asn: geo?.asn ? sanitizeText(geo.asn, 40) : undefined,
  };
}

export function preserveGeoOnLookupFailure(
  existing: Partial<ProxyGeoFields> | undefined,
): ProxyGeoFields | null {
  if (!existing) {
    return null;
  }

  const hasMeaningfulGeo = Boolean(existing.country || existing.countryCode || existing.city || existing.region);
  if (!hasMeaningfulGeo) {
    return null;
  }

  return applyGeoFallback(existing);
}
