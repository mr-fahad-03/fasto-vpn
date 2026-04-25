"use client";

import { Bar, BarChart, CartesianGrid, Cell, Pie, PieChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import type { DashboardStats } from "@/lib/types";
import { Card } from "@/components/ui/Card";

export function DashboardCharts({ stats }: { stats: DashboardStats }) {
  const proxyStatusData = [
    { name: "Active", value: stats.activeVsInactive.active },
    { name: "Inactive", value: stats.activeVsInactive.inactive },
  ];

  const planData = [
    { name: "Free", value: stats.premiumVsFreeProxyCounts.free },
    { name: "Premium", value: stats.premiumVsFreeProxyCounts.premium },
  ];

  const countriesData = stats.proxyCountByCountry.slice(0, 8).map((x) => ({
    country: x.countryCode,
    count: x.count,
  }));

  return (
    <div className="grid gap-4 lg:grid-cols-2">
      <Card>
        <h3 className="mb-3 text-sm font-semibold text-slate-800">Proxy Status</h3>
        <div className="h-56">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={proxyStatusData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="name" />
              <YAxis allowDecimals={false} />
              <Tooltip />
              <Bar dataKey="value" fill="#1f6feb" radius={[6, 6, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </Card>

      <Card>
        <h3 className="mb-3 text-sm font-semibold text-slate-800">Free vs Premium Proxies</h3>
        <div className="h-56">
          <ResponsiveContainer width="100%" height="100%">
            <PieChart>
              <Pie data={planData} dataKey="value" nameKey="name" outerRadius={80} label>
                <Cell fill="#0ea5e9" />
                <Cell fill="#f59e0b" />
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </Card>

      <Card className="lg:col-span-2">
        <h3 className="mb-3 text-sm font-semibold text-slate-800">Top Countries</h3>
        <div className="h-64">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={countriesData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="country" />
              <YAxis allowDecimals={false} />
              <Tooltip />
              <Bar dataKey="count" fill="#14b8a6" radius={[6, 6, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </Card>
    </div>
  );
}
