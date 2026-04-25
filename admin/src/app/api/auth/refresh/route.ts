import { NextResponse } from "next/server";
import { getBackendBaseUrl } from "@/lib/server/backend";
import { clearAuthCookies, readAuthCookies, setAuthCookies } from "@/lib/server/auth-cookies";

export async function POST() {
  try {
    const { refreshToken, role } = await readAuthCookies();

    if (!refreshToken) {
      await clearAuthCookies();
      return NextResponse.json({ success: false, message: "Missing refresh token" }, { status: 401 });
    }

    const response = await fetch(`${getBackendBaseUrl()}/api/v1/admin/auth/refresh`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ refreshToken }),
      cache: "no-store",
    });

    const payload = await response.json();
    if (!response.ok || payload.success === false) {
      await clearAuthCookies();
      return NextResponse.json({ success: false, message: payload.message ?? "Refresh failed" }, { status: 401 });
    }

    await setAuthCookies({
      accessToken: payload.data.accessToken,
      refreshToken: payload.data.refreshToken,
      role: role ?? "admin",
    });

    return NextResponse.json({ success: true });
  } catch {
    await clearAuthCookies();
    return NextResponse.json({ success: false, message: "Refresh failed" }, { status: 500 });
  }
}
