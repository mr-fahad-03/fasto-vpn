"use client";

import { useEffect, useMemo, useState } from "react";
import { api } from "@/lib/client-api";
import type { Paginated, SubscriptionItem } from "@/lib/types";
import { TABLE_PAGE_SIZE } from "@/lib/constants";
import { PageHeader } from "@/components/common/PageHeader";
import { LoadingState, ErrorState, EmptyState } from "@/components/common/States";
import { Input } from "@/components/ui/Input";
import { Select } from "@/components/ui/Select";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Pagination } from "@/components/ui/Pagination";

export default function SubscriptionsPage() {
  const [data, setData] = useState<Paginated<SubscriptionItem> | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [page, setPage] = useState(1);
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState("");
  const [overrideActive, setOverrideActive] = useState("");

  const query = useMemo(
    () => ({ page, limit: TABLE_PAGE_SIZE, search, status, overrideActive, sortBy: "updatedAt", sortOrder: "desc" }),
    [page, search, status, overrideActive],
  );

  const fetchData = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await api.listSubscriptions(query);
      setData(response);
    } catch (fetchError) {
      setError(fetchError instanceof Error ? fetchError.message : "Failed to load subscriptions");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void fetchData();
  }, [page, search, status, overrideActive]);

  async function onOverride(id: string, plan: "free" | "premium") {
    const reason = window.prompt(`Reason for forcing ${plan} plan (optional):`) ?? undefined;
    await api.setSubscriptionOverride(id, plan, reason);
    await fetchData();
  }

  async function onClear(id: string) {
    await api.clearSubscriptionOverride(id);
    await fetchData();
  }

  return (
    <div className="space-y-4">
      <PageHeader title="Subscriptions" description="View and override subscription entitlements." />

      <div className="grid gap-3 rounded-xl border border-slate-200 bg-white p-4 md:grid-cols-4">
        <Input placeholder="Search app user/product" value={search} onChange={(e) => { setSearch(e.target.value); setPage(1); }} />
        <Select value={status} onChange={(e) => { setStatus(e.target.value); setPage(1); }} options={[{label:"All Status",value:""},{label:"free",value:"free"},{label:"premium",value:"premium"},{label:"cancelled",value:"cancelled"}]} />
        <Select value={overrideActive} onChange={(e) => { setOverrideActive(e.target.value); setPage(1); }} options={[{label:"Override: All",value:""},{label:"Override Active",value:"true"},{label:"Override Inactive",value:"false"}]} />
        <Button variant="secondary" onClick={() => { setSearch(""); setStatus(""); setOverrideActive(""); setPage(1); }}>Reset</Button>
      </div>

      {loading && <LoadingState label="Loading subscriptions..." />}
      {error && <ErrorState message={error} />}
      {!loading && !error && data && data.items.length === 0 && <EmptyState label="No subscriptions found." />}

      {!loading && !error && data && data.items.length > 0 && (
        <div className="space-y-3">
          <div className="overflow-x-auto rounded-xl border border-slate-200 bg-white">
            <table className="min-w-full text-left text-sm">
              <thead className="bg-slate-100 text-slate-700">
                <tr>
                  <th className="px-3 py-2">User</th>
                  <th className="px-3 py-2">Plan</th>
                  <th className="px-3 py-2">Status</th>
                  <th className="px-3 py-2">Override</th>
                  <th className="px-3 py-2">Updated</th>
                  <th className="px-3 py-2">Actions</th>
                </tr>
              </thead>
              <tbody>
                {data.items.map((item) => (
                  <tr key={item.id} className="border-t border-slate-100">
                    <td className="px-3 py-2">
                      <div>{item.user?.email ?? "-"}</div>
                      <div className="text-xs text-slate-500">{item.revenueCatAppUserId ?? item.user?.firebaseUid ?? "-"}</div>
                    </td>
                    <td className="px-3 py-2"><Badge label={item.isPremium ? "premium" : "free"} tone={item.isPremium ? "yellow" : "green"} /></td>
                    <td className="px-3 py-2"><Badge label={item.status} tone="blue" /></td>
                    <td className="px-3 py-2">
                      {item.manualOverride?.isActive ? (
                        <Badge label={`forced ${item.manualOverride.plan}`} tone="red" />
                      ) : (
                        <Badge label="none" tone="gray" />
                      )}
                    </td>
                    <td className="px-3 py-2">{new Date(item.updatedAt).toLocaleString()}</td>
                    <td className="px-3 py-2">
                      <div className="flex flex-wrap gap-2">
                        <Button variant="secondary" onClick={() => onOverride(item.id, "premium")}>Force Premium</Button>
                        <Button variant="secondary" onClick={() => onOverride(item.id, "free")}>Force Free</Button>
                        <Button variant="danger" onClick={() => onClear(item.id)}>Clear Override</Button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <Pagination page={data.page} totalPages={data.totalPages} onPage={setPage} />
        </div>
      )}
    </div>
  );
}
