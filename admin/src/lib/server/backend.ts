export function getBackendBaseUrl(): string {
  return process.env.BACKEND_URL ?? process.env.NEXT_PUBLIC_BACKEND_URL ?? "http://localhost:4000";
}

export async function forwardToBackend(params: {
  path: string;
  method: string;
  accessToken?: string;
  body?: string;
}): Promise<Response> {
  const headers: HeadersInit = {
    "Content-Type": "application/json",
  };

  if (params.accessToken) {
    headers.Authorization = `Bearer ${params.accessToken}`;
  }

  return fetch(`${getBackendBaseUrl()}${params.path}`, {
    method: params.method,
    headers,
    body: params.body,
    cache: "no-store",
  });
}
