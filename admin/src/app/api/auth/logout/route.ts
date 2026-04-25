import { NextResponse } from "next/server";
import { getBackendBaseUrl } from "@/lib/server/backend";
import { clearAuthCookies, readAuthCookies } from "@/lib/server/auth-cookies";

export async function POST() {
  const { refreshToken } = await readAuthCookies();

  if (refreshToken) {
    try {
      await fetch(`${getBackendBaseUrl()}/api/v1/admin/auth/logout`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ refreshToken }),
        cache: "no-store",
      });
    } catch {
      // ignore network errors during logout
    }
  }

  await clearAuthCookies();
  return NextResponse.json({ success: true });
}
