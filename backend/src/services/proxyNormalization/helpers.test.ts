import { describe, expect, it } from "vitest";
import {
  applyGeoFallback,
  isPrivateIpv4,
  normalizeHostInput,
  normalizeTags,
  preserveGeoOnLookupFailure,
  sanitizeText,
  unknownGeoFields,
  validateProxyFields,
} from "./helpers";

describe("proxyNormalization/helpers", () => {
  it("sanitizes and trims text", () => {
    expect(sanitizeText("  proxy\u0000-name  ")).toBe("proxy-name");
  });

  it("normalizes host input", () => {
    expect(normalizeHostInput("  ExAmPle.COM ")).toBe("example.com");
  });

  it("normalizes tags (trim, lowercase, dedupe)", () => {
    expect(normalizeTags(["  US  ", "us", " Premium ", ""]))
      .toEqual(["us", "premium"]);
  });

  it("validates proxy fields", () => {
    expect(
      validateProxyFields({
        port: 443,
        type: "SOCKS5",
        username: "proxyuser",
        password: "proxypass",
      }),
    ).toEqual([]);

    expect(
      validateProxyFields({
        port: 70000,
        type: "FTP",
        username: "proxyuser",
      }),
    ).toEqual([
      "Port must be an integer between 1 and 65535",
      "Unsupported proxy type. Only HTTP and SOCKS5 are allowed",
      "Username and password must be provided together",
    ]);
  });

  it("detects private IPv4 ranges accurately", () => {
    expect(isPrivateIpv4("172.16.0.1")).toBe(true);
    expect(isPrivateIpv4("172.31.255.254")).toBe(true);
    expect(isPrivateIpv4("172.237.73.24")).toBe(false);
    expect(isPrivateIpv4("8.8.8.8")).toBe(false);
    expect(isPrivateIpv4("127.0.0.1")).toBe(true);
  });

  it("applies geo fallback defaults", () => {
    expect(applyGeoFallback(undefined)).toEqual({
      country: "Unknown",
      countryCode: "XX",
      region: undefined,
      city: undefined,
      timezone: undefined,
      isp: undefined,
      asn: undefined,
    });

    expect(unknownGeoFields()).toEqual({
      country: "Unknown",
      countryCode: "XX",
    });
  });

  it("preserves existing geo on lookup failure", () => {
    expect(
      preserveGeoOnLookupFailure({
        country: "Germany",
        countryCode: "de",
        city: "Berlin",
        region: "Berlin",
        timezone: "Europe/Berlin",
      }),
    ).toEqual({
      country: "Germany",
      countryCode: "DE",
      city: "Berlin",
      region: "Berlin",
      timezone: "Europe/Berlin",
      isp: undefined,
      asn: undefined,
    });

    expect(preserveGeoOnLookupFailure(undefined)).toBeNull();
  });
});
