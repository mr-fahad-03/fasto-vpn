import { cookies } from "next/headers";
import { COOKIE_NAMES } from "@/lib/constants";

type SetAuthCookiesInput = {
  accessToken: string;
  refreshToken: string;
  role: string;
};

function cookieOptions(maxAgeSeconds: number) {
  return {
    httpOnly: true,
    secure: process.env.COOKIE_SECURE === "true",
    sameSite: "lax" as const,
    path: "/",
    maxAge: maxAgeSeconds,
  };
}

export async function setAuthCookies(input: SetAuthCookiesInput): Promise<void> {
  const store = await cookies();

  store.set(COOKIE_NAMES.accessToken, input.accessToken, cookieOptions(60 * 15));
  store.set(COOKIE_NAMES.refreshToken, input.refreshToken, cookieOptions(60 * 60 * 24 * 30));
  store.set(COOKIE_NAMES.role, input.role, cookieOptions(60 * 60 * 24 * 30));
}

export async function clearAuthCookies(): Promise<void> {
  const store = await cookies();

  store.set(COOKIE_NAMES.accessToken, "", cookieOptions(0));
  store.set(COOKIE_NAMES.refreshToken, "", cookieOptions(0));
  store.set(COOKIE_NAMES.role, "", cookieOptions(0));
}

export async function readAuthCookies(): Promise<{ accessToken?: string; refreshToken?: string; role?: string }> {
  const store = await cookies();
  return {
    accessToken: store.get(COOKIE_NAMES.accessToken)?.value,
    refreshToken: store.get(COOKIE_NAMES.refreshToken)?.value,
    role: store.get(COOKIE_NAMES.role)?.value,
  };
}
