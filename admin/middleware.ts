import { NextRequest, NextResponse } from "next/server";
import { COOKIE_NAMES } from "./src/lib/constants";

const protectedPrefixes = ["/dashboard", "/proxies", "/users", "/subscriptions", "/settings"];

export function middleware(req: NextRequest) {
  const accessToken = req.cookies.get(COOKIE_NAMES.accessToken)?.value;
  const role = req.cookies.get(COOKIE_NAMES.role)?.value;
  const isProtected = protectedPrefixes.some((prefix) => req.nextUrl.pathname.startsWith(prefix));

  if (isProtected && (!accessToken || role !== "admin")) {
    return NextResponse.redirect(new URL("/login", req.url));
  }

  if (req.nextUrl.pathname === "/login" && accessToken && role === "admin") {
    return NextResponse.redirect(new URL("/dashboard", req.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/login", "/dashboard/:path*", "/proxies/:path*", "/users/:path*", "/subscriptions/:path*", "/settings/:path*"],
};
