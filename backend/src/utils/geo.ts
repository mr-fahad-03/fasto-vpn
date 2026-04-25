import net from "net";
import { env } from "../config/env";

export type GeoLookupResult = {
  country: string;
  countryCode: string;
  city?: string;
  region?: string;
  isp?: string;
};

function isPrivateIp(ip: string): boolean {
  return (
    ip.startsWith("10.") ||
    ip.startsWith("127.") ||
    ip.startsWith("192.168.") ||
    ip.startsWith("172.16.") ||
    ip.startsWith("172.17.") ||
    ip.startsWith("172.18.") ||
    ip.startsWith("172.19.") ||
    ip.startsWith("172.2") ||
    ip === "0.0.0.0"
  );
}

export async function lookupGeo(ip: string): Promise<GeoLookupResult> {
  if (!net.isIP(ip) || isPrivateIp(ip)) {
    return { country: "Unknown", countryCode: "XX" };
  }

  try {
    const response = await fetch(`${env.GEO_LOOKUP_URL}/${ip}`);
    if (!response.ok) {
      return { country: "Unknown", countryCode: "XX" };
    }

    const data = (await response.json()) as {
      success?: boolean;
      country?: string;
      country_code?: string;
      city?: string;
      region?: string;
      connection?: { isp?: string };
    };

    if (data.success === false) {
      return { country: "Unknown", countryCode: "XX" };
    }

    return {
      country: data.country ?? "Unknown",
      countryCode: data.country_code ?? "XX",
      city: data.city,
      region: data.region,
      isp: data.connection?.isp,
    };
  } catch {
    return { country: "Unknown", countryCode: "XX" };
  }
}
