import { NextRequest, NextResponse } from "next/server";
import { getBackendBaseUrl } from "@/lib/server/backend";
import { clearAuthCookies, readAuthCookies, setAuthCookies } from "@/lib/server/auth-cookies";

type RouteContext = {
  params: Promise<{ path: string[] }>;
};

async function refreshAccessToken(refreshToken?: string, role = "admin"): Promise<string | null> {
  if (!refreshToken) {
    return null;
  }

  const response = await fetch(`${getBackendBaseUrl()}/api/v1/admin/auth/refresh`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ refreshToken }),
    cache: "no-store",
  });

  const payload = await response.json();
  if (!response.ok || payload.success === false) {
    return null;
  }

  await setAuthCookies({
    accessToken: payload.data.accessToken,
    refreshToken: payload.data.refreshToken,
    role,
  });

  return payload.data.accessToken as string;
}

async function forward(req: NextRequest, ctx: RouteContext, method: string) {
  const { path } = await ctx.params;
  const targetPath = `/api/v1/admin/${path.join("/")}${req.nextUrl.search}`;
  const { accessToken, refreshToken, role } = await readAuthCookies();

  if (!accessToken || role !== "admin") {
    await clearAuthCookies();
    return NextResponse.json({ success: false, message: "Unauthorized" }, { status: 401 });
  }

  const hasBody = method !== "GET" && method !== "HEAD";
  const body = hasBody ? await req.text() : undefined;

  const callBackend = (token: string) =>
    fetch(`${getBackendBaseUrl()}${targetPath}`, {
      method,
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`,
      },
      body,
      cache: "no-store",
    });

  let response = await callBackend(accessToken);

  if (response.status === 401 || response.status === 403) {
    const renewedToken = await refreshAccessToken(refreshToken, role);
    if (!renewedToken) {
      await clearAuthCookies();
      return NextResponse.json({ success: false, message: "Unauthorized" }, { status: 401 });
    }

    response = await callBackend(renewedToken);

    if (response.status === 401 || response.status === 403) {
      await clearAuthCookies();
      return NextResponse.json({ success: false, message: "Unauthorized" }, { status: 401 });
    }
  }

  const text = await response.text();
  const contentType = response.headers.get("content-type") ?? "application/json";

  return new NextResponse(text, {
    status: response.status,
    headers: {
      "Content-Type": contentType,
    },
  });
}

export async function GET(req: NextRequest, ctx: RouteContext) {
  return forward(req, ctx, "GET");
}

export async function POST(req: NextRequest, ctx: RouteContext) {
  return forward(req, ctx, "POST");
}

export async function PATCH(req: NextRequest, ctx: RouteContext) {
  return forward(req, ctx, "PATCH");
}

export async function PUT(req: NextRequest, ctx: RouteContext) {
  return forward(req, ctx, "PUT");
}

export async function DELETE(req: NextRequest, ctx: RouteContext) {
  return forward(req, ctx, "DELETE");
}
