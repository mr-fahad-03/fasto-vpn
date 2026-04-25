import dns from "dns/promises";
import net from "net";

export async function resolveHostToIp(hostOrIp: string): Promise<string> {
  const host = hostOrIp.trim();
  if (net.isIP(host)) {
    return host;
  }

  const result = await dns.lookup(host, { family: 4 });
  return result.address;
}
