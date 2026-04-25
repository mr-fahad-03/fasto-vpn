"use client";

import { useEffect, useState } from "react";
import { api } from "@/lib/client-api";
import type { ActivityItem, DashboardStats } from "@/lib/types";
import { PageHeader } from "@/components/common/PageHeader";
import { Card } from "@/components/ui/Card";
import { LoadingState, ErrorState, EmptyState } from "@/components/common/States";
import { DashboardCharts } from "@/components/dashboard/Charts";

export default function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [activity, setActivity] = useState<ActivityItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    (async () => {
      setLoading(true);
      setError(null);
      try {
        const [statsData, activityData] = await Promise.all([api.getDashboardStats(), api.getRecentActivity(20)]);
        setStats(statsData);
        setActivity(activityData);
      } catch (fetchError) {
        setError(fetchError instanceof Error ? fetchError.message : "Failed to load dashboard");
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  if (loading) return <LoadingState label="Loading dashboard..." />;
  if (error) return <ErrorState message={error} />;
  if (!stats) return <EmptyState label="No dashboard data available." />;

  const countriesCount = stats.proxyCountByCountry.length;

  return (
    <div className="space-y-4">
      <PageHeader title="Dashboard" description="Overview of proxies, users, and subscriptions." />

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
        <Card><p className="text-sm text-slate-500">Total Proxies</p><p className="mt-1 text-2xl font-semibold">{stats.activeVsInactive.active + stats.activeVsInactive.inactive}</p></Card>
        <Card><p className="text-sm text-slate-500">Active Proxies</p><p className="mt-1 text-2xl font-semibold">{stats.activeVsInactive.active}</p></Card>
        <Card><p className="text-sm text-slate-500">Countries Count</p><p className="mt-1 text-2xl font-semibold">{countriesCount}</p></Card>
        <Card><p className="text-sm text-slate-500">Free Proxies</p><p className="mt-1 text-2xl font-semibold">{stats.premiumVsFreeProxyCounts.free}</p></Card>
        <Card><p className="text-sm text-slate-500">Premium Proxies</p><p className="mt-1 text-2xl font-semibold">{stats.premiumVsFreeProxyCounts.premium}</p></Card>
        <Card><p className="text-sm text-slate-500">Total Users</p><p className="mt-1 text-2xl font-semibold">{stats.userStats.totalUsers}</p></Card>
        <Card><p className="text-sm text-slate-500">Premium Users</p><p className="mt-1 text-2xl font-semibold">{stats.userStats.premiumUsers}</p></Card>
      </div>

      <DashboardCharts stats={stats} />

      <Card>
        <h3 className="mb-3 text-sm font-semibold text-slate-800">Recent Activity</h3>
        {activity.length === 0 ? (
          <EmptyState label="No recent activity." />
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full text-left text-sm">
              <thead className="bg-slate-100 text-slate-600">
                <tr>
                  <th className="px-3 py-2">Time</th>
                  <th className="px-3 py-2">Event</th>
                  <th className="px-3 py-2">User</th>
                  <th className="px-3 py-2">IP</th>
                </tr>
              </thead>
              <tbody>
                {activity.map((item) => (
                  <tr key={item.id} className="border-t border-slate-100">
                    <td className="px-3 py-2">{new Date(item.createdAt).toLocaleString()}</td>
                    <td className="px-3 py-2">{item.eventType}</td>
                    <td className="px-3 py-2">{item.user?.email ?? item.user?.firebaseUid ?? "-"}</td>
                    <td className="px-3 py-2">{item.ip ?? "-"}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>
    </div>
  );
}
