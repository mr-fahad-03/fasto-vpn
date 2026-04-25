export const SUPPORTED_PROXY_TYPES = ["HTTP", "SOCKS5"] as const;

export type SupportedProxyType = (typeof SUPPORTED_PROXY_TYPES)[number];

export function isSupportedProxyType(value: string): value is SupportedProxyType {
  return (SUPPORTED_PROXY_TYPES as readonly string[]).includes(value);
}

export function normalizeProxyType(value: string | undefined): SupportedProxyType | undefined {
  if (!value) {
    return undefined;
  }

  const upper = value.trim().toUpperCase();

  if (upper === "HTTP" || upper === "HTTPS") {
    return "HTTP";
  }

  if (upper === "SOCKS" || upper === "SOCKS5") {
    return "SOCKS5";
  }

  return undefined;
}

type ParsedProxyImportItem = {
  host: string;
  port: number;
  type: SupportedProxyType;
};

function parseCompactHostPort(line: string): ParsedProxyImportItem | null {
  const compact = line.trim();
  const matches = compact.match(/^(.+):(\d+)(?::([A-Za-z0-9]+))?$/);
  if (!matches) {
    return null;
  }

  const host = matches[1].trim();
  const port = Number(matches[2].trim());
  const parsedType = normalizeProxyType(matches[3]);

  if (!host || !Number.isInteger(port) || port < 1 || port > 65535) {
    return null;
  }

  return {
    host,
    port,
    type: parsedType ?? "HTTP",
  };
}

function parseUrlStyleLine(line: string): ParsedProxyImportItem | null {
  try {
    const url = new URL(line.trim());
    const host = url.hostname?.trim();
    const port = Number(url.port);
    const type = normalizeProxyType(url.protocol.replace(":", ""));

    if (!host || !Number.isInteger(port) || port < 1 || port > 65535 || !type) {
      return null;
    }

    return { host, port, type };
  } catch {
    return null;
  }
}

function parseTableStyleLine(line: string): ParsedProxyImportItem | null {
  const tokens = line
    .trim()
    .split(/[\s,\t]+/)
    .map((token) => token.trim())
    .filter(Boolean);

  if (tokens.length < 2) {
    return null;
  }

  const host = tokens[0];
  const port = Number(tokens[1]);
  const parsedType = normalizeProxyType(tokens[2]);

  if (!host || !Number.isInteger(port) || port < 1 || port > 65535) {
    return null;
  }

  return {
    host,
    port,
    type: parsedType ?? "HTTP",
  };
}

export function parseProxyBulkText(rawText: string): ParsedProxyImportItem[] {
  const normalizedText = rawText.replace(/\r/g, "");
  const rows: ParsedProxyImportItem[] = [];
  const seen = new Set<string>();

  for (const rawLine of normalizedText.split("\n")) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#")) {
      continue;
    }

    let parsed: ParsedProxyImportItem | null = null;

    if (line.includes("://")) {
      parsed = parseUrlStyleLine(line);
    }

    if (!parsed && line.includes(":")) {
      parsed = parseCompactHostPort(line);
    }

    if (!parsed) {
      parsed = parseTableStyleLine(line);
    }

    if (!parsed) {
      continue;
    }

    const dedupeKey = `${parsed.host.toLowerCase()}:${parsed.port}:${parsed.type}`;
    if (seen.has(dedupeKey)) {
      continue;
    }

    seen.add(dedupeKey);
    rows.push(parsed);
  }

  return rows;
}
