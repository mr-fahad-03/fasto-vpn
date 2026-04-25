import { describe, expect, it, vi } from "vitest";
import { normalizeProxyInput } from "./service";
import { GeoLookupProvider } from "./provider";
import { ApiError } from "../../utils/ApiError";

describe("proxyNormalization/service", () => {
  it("resolves hostname and enriches geo data", async () => {
    const provider: GeoLookupProvider = {
      providerName: "mock-provider",
      lookup: vi.fn(async () => ({
        success: true,
        geo: {
          country: "Germany",
          countryCode: "DE",
          region: "Berlin",
          city: "Berlin",
          timezone: "Europe/Berlin",
          isp: "Mock ISP",
          asn: "AS1234",
        },
        raw: { source: "mock" },
      })),
    };

    const dnsResolver = vi.fn(async () => "1.1.1.1");

    const normalized = await normalizeProxyInput(
      {
        name: "  Main Node ",
        host: "Example.com",
        port: 443,
        type: "HTTP",
        tags: ["  Free ", "free", "US"],
      },
      { geoProvider: provider, dnsResolver },
    );

    expect(dnsResolver).toHaveBeenCalledWith("example.com");
    expect(normalized.name).toBe("Main Node");
    expect(normalized.host).toBe("example.com");
    expect(normalized.resolvedIp).toBe("1.1.1.1");
    expect(normalized.country).toBe("Germany");
    expect(normalized.countryCode).toBe("DE");
    expect(normalized.timezone).toBe("Europe/Berlin");
    expect(normalized.isp).toBe("Mock ISP");
    expect(normalized.asn).toBe("AS1234");
    expect(normalized.tags).toEqual(["free", "us"]);
    expect(normalized.geoLookupStatus).toBe("success");
    expect(normalized.geoLookupRaw).toEqual({ source: "mock" });
  });

  it("skips DNS when input is already an IP", async () => {
    const provider: GeoLookupProvider = {
      providerName: "mock-provider",
      lookup: vi.fn(async () => ({
        success: true,
        geo: {
          country: "France",
          countryCode: "FR",
        },
        raw: { source: "mock" },
      })),
    };

    const dnsResolver = vi.fn(async () => "should-not-be-used");

    const normalized = await normalizeProxyInput(
      {
        name: "Proxy",
        host: "8.8.8.8",
        port: 443,
        type: "SOCKS5",
      },
      { geoProvider: provider, dnsResolver },
    );

    expect(dnsResolver).not.toHaveBeenCalled();
    expect(normalized.resolvedIp).toBe("8.8.8.8");
    expect(normalized.countryCode).toBe("FR");
  });

  it("falls back to Unknown on lookup failure for create", async () => {
    const provider: GeoLookupProvider = {
      providerName: "mock-provider",
      lookup: vi.fn(async () => ({
        success: false,
        raw: { message: "rate_limited" },
        error: "Provider unavailable",
      })),
    };

    const normalized = await normalizeProxyInput(
      {
        name: "Proxy",
        host: "example.com",
        port: 443,
        type: "HTTP",
      },
      {
        geoProvider: provider,
        dnsResolver: async () => "5.5.5.5",
      },
    );

    expect(normalized.country).toBe("Unknown");
    expect(normalized.countryCode).toBe("XX");
    expect(normalized.geoLookupStatus).toBe("fallback");
    expect(normalized.geoLookupError).toBe("Provider unavailable");
    expect(normalized.geoLookupRaw).toEqual({ message: "rate_limited" });
  });

  it("keeps existing geo fields on update when lookup fails", async () => {
    const provider: GeoLookupProvider = {
      providerName: "mock-provider",
      lookup: vi.fn(async () => ({
        success: false,
        raw: { message: "timeout" },
        error: "Provider timeout",
      })),
    };

    const normalized = await normalizeProxyInput(
      {
        name: "Proxy",
        host: "new-host.example",
        port: 443,
        type: "HTTP",
      },
      {
        geoProvider: provider,
        dnsResolver: async () => "9.9.9.9",
        existing: {
          host: "old-host.example",
          ip: "2.2.2.2",
          country: "United States",
          countryCode: "US",
          region: "California",
          city: "San Francisco",
          timezone: "America/Los_Angeles",
          isp: "Old ISP",
          asn: "AS9999",
        },
      },
    );

    expect(normalized.geoLookupStatus).toBe("failed");
    expect(normalized.country).toBe("United States");
    expect(normalized.countryCode).toBe("US");
    expect(normalized.city).toBe("San Francisco");
    expect(normalized.timezone).toBe("America/Los_Angeles");
    expect(normalized.isp).toBe("Old ISP");
    expect(normalized.asn).toBe("AS9999");
  });

  it("reuses existing geo metadata when host is unchanged", async () => {
    const provider: GeoLookupProvider = {
      providerName: "mock-provider",
      lookup: vi.fn(async () => ({
        success: true,
        geo: { country: "Never Used", countryCode: "NU" },
        raw: { should: "not-be-used" },
      })),
    };

    const normalized = await normalizeProxyInput(
      {
        name: "Proxy",
        host: "same.example",
        port: 443,
        type: "HTTP",
      },
      {
        geoProvider: provider,
        dnsResolver: async () => "7.7.7.7",
        existing: {
          host: "same.example",
          ip: "7.7.7.7",
          country: "Canada",
          countryCode: "CA",
          city: "Toronto",
          region: "Ontario",
          geoLookupStatus: "success",
          geoLookupRaw: { reused: true },
          geoLookupProvider: "legacy",
        },
      },
    );

    expect(provider.lookup).not.toHaveBeenCalled();
    expect(normalized.country).toBe("Canada");
    expect(normalized.countryCode).toBe("CA");
    expect(normalized.geoLookupRaw).toEqual({ reused: true });
    expect(normalized.geoLookupStatus).toBe("success");
  });

  it("rejects private and loopback proxy hosts", async () => {
    await expect(
      normalizeProxyInput({
        name: "Local Proxy",
        host: "127.0.0.7",
        port: 8080,
        type: "HTTP",
      }),
    ).rejects.toBeInstanceOf(ApiError);
  });
});
