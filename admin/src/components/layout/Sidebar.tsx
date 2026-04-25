"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import clsx from "clsx";
import { Button } from "@/components/ui/Button";
import { api } from "@/lib/client-api";

const links = [
  { href: "/dashboard", label: "Dashboard" },
  { href: "/proxies", label: "Proxies" },
  { href: "/users", label: "Users" },
  { href: "/subscriptions", label: "Subscriptions" },
  { href: "/settings", label: "Settings" },
];

export function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();

  async function onLogout() {
    await api.logout();
    router.push("/login");
  }

  return (
    <aside className="w-full border-b border-slate-200 bg-white lg:w-64 lg:border-b-0 lg:border-r">
      <div className="p-4">
        <h2 className="text-lg font-bold text-brand-700">Fasto VPN Admin</h2>
      </div>
      <nav className="space-y-1 px-2 pb-4">
        {links.map((link) => {
          const active = pathname === link.href || pathname.startsWith(`${link.href}/`);
          return (
            <Link
              key={link.href}
              href={link.href}
              className={clsx(
                "block rounded-md px-3 py-2 text-sm",
                active ? "bg-brand-100 text-brand-800" : "text-slate-700 hover:bg-slate-100",
              )}
            >
              {link.label}
            </Link>
          );
        })}
      </nav>
      <div className="px-4 pb-4">
        <Button variant="secondary" className="w-full" onClick={onLogout}>
          Logout
        </Button>
      </div>
    </aside>
  );
}
