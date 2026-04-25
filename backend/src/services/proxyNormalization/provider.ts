import {
  applyGeoFallback,
  GEO_UNKNOWN_COUNTRY,
  GEO_UNKNOWN_COUNTRY_CODE,
  ProxyGeoFields,
} from "./helpers";

export type GeoLookupStatus = "success" | "fallback" | "failed";

export type GeoProviderLookupResult = {
  success: boolean;
  geo?: ProxyGeoFields;
  raw: Record<string, unknown>;
  error?: string;
};

export interface GeoLookupProvider {
  readonly providerName: string;
  lookup(ip: string): Promise<GeoProviderLookupResult>;
}

export class IpWhoisGeoLookupProvider implements GeoLookupProvider {
  readonly providerName = "ipwho.is";

  constructor(
    private readonly baseUrl: string,
    private readonly timeoutMs = 3500,
  ) {}

  async lookup(ip: string): Promise<GeoProviderLookupResult> {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), this.timeoutMs);

    try {
      const response = await fetch(`${this.baseUrl}/${encodeURIComponent(ip)}`, {
        signal: controller.signal,
      });

      const payload = (await response.json()) as Record<string, unknown>;

      if (!response.ok) {
        return {
          success: false,
          raw: payload,
          error: `Lookup HTTP ${response.status}`,
        };
      }

      if (payload.success === false) {
        return {
          success: false,
          raw: payload,
          error: "Lookup provider marked request unsuccessful",
        };
      }

      const timezoneValue =
        typeof payload.timezone === "string"
          ? payload.timezone
          : typeof payload.timezone === "object" && payload.timezone
            ? ((payload.timezone as Record<string, unknown>).id as string | undefined)
            : undefined;

      const connection =
        typeof payload.connection === "object" && payload.connection
          ? (payload.connection as Record<string, unknown>)
          : {};

      const fallbackAsn =
        typeof payload.asn === "string"
          ? payload.asn
          : typeof payload.asn === "number"
            ? String(payload.asn)
            : undefined;

      const fallbackIsp =
        typeof payload.isp === "string"
          ? payload.isp
          : typeof payload.org === "string"
            ? payload.org
            : undefined;

      const normalized = applyGeoFallback({
        country: typeof payload.country === "string" ? payload.country : GEO_UNKNOWN_COUNTRY,
        countryCode:
          typeof payload.country_code === "string"
            ? payload.country_code
            : GEO_UNKNOWN_COUNTRY_CODE,
        region: typeof payload.region === "string" ? payload.region : undefined,
        city: typeof payload.city === "string" ? payload.city : undefined,
        timezone: timezoneValue,
        isp: typeof connection.isp === "string" ? connection.isp : fallbackIsp,
        asn:
          typeof connection.asn === "string"
            ? connection.asn
            : typeof connection.asn === "number"
              ? String(connection.asn)
              : fallbackAsn,
      });

      return {
        success: true,
        geo: normalized,
        raw: payload,
      };
    } catch (error) {
      return {
        success: false,
        raw: {
          error: error instanceof Error ? error.message : "Unknown provider error",
        },
        error: error instanceof Error ? error.message : "Unknown provider error",
      };
    } finally {
      clearTimeout(timeout);
    }
  }
}

export function createDefaultGeoLookupProvider(): GeoLookupProvider {
  const baseUrl = process.env.GEO_LOOKUP_URL || "https://ipwhois.app/json";
  return new IpWhoisGeoLookupProvider(baseUrl);
}
