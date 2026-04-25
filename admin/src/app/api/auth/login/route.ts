import { NextRequest, NextResponse } from "next/server";
import { getBackendBaseUrl } from "@/lib/server/backend";
import { clearAuthCookies, setAuthCookies } from "@/lib/server/auth-cookies";

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();

    const response = await fetch(`${getBackendBaseUrl()}/api/v1/admin/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
      cache: "no-store",
    });

    const payload = await response.json();

    if (!response.ok || payload.success === false) {
      await clearAuthCookies();
      return NextResponse.json(
        {
          success: false,
          message: payload.message ?? "Login failed",
        },
        { status: response.status || 401 },
      );
    }

    await setAuthCookies({
      accessToken: payload.data.accessToken,
      refreshToken: payload.data.refreshToken,
      role: payload.data.admin?.role ?? "admin",
    });

    return NextResponse.json({
      success: true,
      data: {
        admin: payload.data.admin,
      },
    });
  } catch (error) {
    return NextResponse.json(
      {
        success: false,
        message: error instanceof Error ? error.message : "Login failed",
      },
      { status: 500 },
    );
  }
}
