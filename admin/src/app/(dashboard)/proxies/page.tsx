"use client";

import Link from "next/link";
import { useEffect, useMemo, useRef, useState } from "react";
import { api } from "@/lib/client-api";
import type { Paginated, ProxyItem } from "@/lib/types";
import { TABLE_PAGE_SIZE } from "@/lib/constants";
import { PageHeader } from "@/components/common/PageHeader";
import { LoadingState, ErrorState, EmptyState } from "@/components/common/States";
import { Input } from "@/components/ui/Input";
import { Select } from "@/components/ui/Select";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Pagination } from "@/components/ui/Pagination";

export default function ProxiesPage() {
  const [data, setData] = useState<Paginated<ProxyItem> | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [page, setPage] = useState(1);
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState("");
  const [isPremium, setIsPremium] = useState("");
  const [sortBy, setSortBy] = useState("sortOrder");
  const [sortOrder, setSortOrder] = useState<"asc" | "desc">("asc");
  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  const [bulkBusy, setBulkBusy] = useState(false);
  const [selectingAllFiltered, setSelectingAllFiltered] = useState(false);
  const selectAllRef = useRef<HTMLInputElement | null>(null);

  const query = useMemo(
    () => ({ page, limit: TABLE_PAGE_SIZE, search, status, isPremium, sortBy, sortOrder }),
    [page, search, status, isPremium, sortBy, sortOrder],
  );
  const selectedIdSet = useMemo(() => new Set(selectedIds), [selectedIds]);
  const visibleIds = useMemo(() => data?.items.map((item) => item.id) ?? [], [data]);
  const allVisibleSelected = visibleIds.length > 0 && visibleIds.every((id) => selectedIdSet.has(id));
  const someVisibleSelected = visibleIds.some((id) => selectedIdSet.has(id)) && !allVisibleSelected;

  const fetchData = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await api.listProxies(query);
      setData(response);
    } catch (fetchError) {
      setError(fetchError instanceof Error ? fetchError.message : "Failed to load proxies");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void fetchData();
  }, [page, search, status, isPremium, sortBy, sortOrder]);

  useEffect(() => {
    if (!selectAllRef.current) return;
    selectAllRef.current.indeterminate = someVisibleSelected;
  }, [someVisibleSelected]);

  useEffect(() => {
    setSelectedIds([]);
  }, [search, status, isPremium, sortBy, sortOrder]);

  async function onDelete(id: string) {
    if (!window.confirm("Delete this proxy?")) return;
    await api.deleteProxy(id);
    await fetchData();
  }

  async function onToggleStatus(id: string, nextStatus: "active" | "inactive") {
    await api.updateProxyStatus(id, nextStatus);
    await fetchData();
  }

  function toggleRowSelection(id: string, checked: boolean) {
    setSelectedIds((prev) => {
      if (checked) {
        if (prev.includes(id)) return prev;
        return [...prev, id];
      }
      return prev.filter((item) => item !== id);
    });
  }

  function toggleVisibleSelection(checked: boolean) {
    setSelectedIds((prev) => {
      if (checked) {
        return Array.from(new Set([...prev, ...visibleIds]));
      }
      const visibleIdSet = new Set(visibleIds);
      return prev.filter((id) => !visibleIdSet.has(id));
    });
  }

  async function selectAllFiltered() {
    setSelectingAllFiltered(true);
    setError(null);

    try {
      const baseQuery = { search, status, isPremium, sortBy, sortOrder, limit: 100 };
      const firstPage = await api.listProxies({ ...baseQuery, page: 1 });
      const ids = firstPage.items.map((item) => item.id);

      for (let nextPage = 2; nextPage <= firstPage.totalPages; nextPage += 1) {
        const pageData = await api.listProxies({ ...baseQuery, page: nextPage });
        ids.push(...pageData.items.map((item) => item.id));
      }

      setSelectedIds(Array.from(new Set(ids)));
    } catch (fetchError) {
      setError(fetchError instanceof Error ? fetchError.message : "Failed to select proxies");
    } finally {
      setSelectingAllFiltered(false);
    }
  }

  async function onBulkStatus(nextStatus: "active" | "inactive") {
    if (selectedIds.length === 0) return;
    setBulkBusy(true);
    setError(null);

    try {
      const results = await Promise.allSettled(
        selectedIds.map((id) => api.updateProxyStatus(id, nextStatus)),
      );
      const failed = results.filter((result) => result.status === "rejected").length;
      await fetchData();

      if (failed > 0) {
        setError(`${failed} proxy update(s) failed. Others were processed.`);
      } else {
        setSelectedIds([]);
      }
    } catch (updateError) {
      setError(updateError instanceof Error ? updateError.message : "Bulk status update failed");
    } finally {
      setBulkBusy(false);
    }
  }

  async function onBulkDelete() {
    if (selectedIds.length === 0) return;
    if (!window.confirm(`Delete ${selectedIds.length} selected proxies?`)) return;

    setBulkBusy(true);
    setError(null);

    try {
      const results = await Promise.allSettled(selectedIds.map((id) => api.deleteProxy(id)));
      const failed = results.filter((result) => result.status === "rejected").length;
      await fetchData();

      if (failed > 0) {
        setError(`${failed} proxy deletion(s) failed. Others were processed.`);
      } else {
        setSelectedIds([]);
      }
    } catch (deleteError) {
      setError(deleteError instanceof Error ? deleteError.message : "Bulk delete failed");
    } finally {
      setBulkBusy(false);
    }
  }

  return (
    <div className="space-y-4">
      <PageHeader
        title="Proxies"
        description="Manage HTTP and SOCKS5 proxy endpoints."
        action={
          <div className="flex gap-2">
            <Link href="/proxies/import"><Button variant="secondary">Bulk Import</Button></Link>
            <Link href="/proxies/new"><Button>Add Proxy</Button></Link>
          </div>
        }
      />

      <div className="grid gap-3 rounded-xl border border-slate-200 bg-white p-4 md:grid-cols-3 lg:grid-cols-6">
        <Input placeholder="Search name/host/country" value={search} onChange={(e) => { setSearch(e.target.value); setPage(1); }} />
        <Select value={status} onChange={(e) => { setStatus(e.target.value); setPage(1); }} options={[{label:"All Status",value:""},{label:"Active",value:"active"},{label:"Inactive",value:"inactive"}]} />
        <Select value={isPremium} onChange={(e) => { setIsPremium(e.target.value); setPage(1); }} options={[{label:"All Plans",value:""},{label:"Free",value:"false"},{label:"Premium",value:"true"}]} />
        <Select value={sortBy} onChange={(e) => setSortBy(e.target.value)} options={[{label:"Sort: Order",value:"sortOrder"},{label:"Sort: Name",value:"name"},{label:"Sort: Country",value:"country"},{label:"Sort: Updated",value:"updatedAt"}]} />
        <Select value={sortOrder} onChange={(e) => setSortOrder(e.target.value as "asc" | "desc")} options={[{label:"Asc",value:"asc"},{label:"Desc",value:"desc"}]} />
        <Button variant="secondary" onClick={() => { setSearch(""); setStatus(""); setIsPremium(""); setSortBy("sortOrder"); setSortOrder("asc"); setPage(1); }}>Reset</Button>
      </div>

      {loading && <LoadingState label="Loading proxies..." />}
      {error && <ErrorState message={error} />}

      {!loading && !error && data && data.items.length === 0 && <EmptyState label="No proxies found." />}

      {!loading && !error && data && data.items.length > 0 && (
        <div className="space-y-3">
          <div className="flex flex-wrap items-center gap-2 rounded-xl border border-slate-200 bg-white p-3">
            <span className="text-sm text-slate-700">
              Selected: <strong>{selectedIds.length}</strong>
            </span>
            <Button
              variant="secondary"
              onClick={selectAllFiltered}
              disabled={loading || bulkBusy || selectingAllFiltered}
            >
              {selectingAllFiltered ? "Selecting..." : "Select All (Filtered)"}
            </Button>
            <Button
              variant="secondary"
              onClick={() => onBulkStatus("active")}
              disabled={selectedIds.length === 0 || loading || bulkBusy}
            >
              Activate Selected
            </Button>
            <Button
              variant="secondary"
              onClick={() => onBulkStatus("inactive")}
              disabled={selectedIds.length === 0 || loading || bulkBusy}
            >
              Deactivate Selected
            </Button>
            <Button
              variant="danger"
              onClick={onBulkDelete}
              disabled={selectedIds.length === 0 || loading || bulkBusy}
            >
              Delete Selected
            </Button>
            {selectedIds.length > 0 && (
              <Button variant="secondary" onClick={() => setSelectedIds([])} disabled={loading || bulkBusy}>
                Clear Selection
              </Button>
            )}
          </div>

          <div className="overflow-x-auto rounded-xl border border-slate-200 bg-white">
            <table className="min-w-full text-left text-sm">
              <thead className="bg-slate-100 text-slate-700">
                <tr>
                  <th className="px-3 py-2">
                    <input
                      ref={selectAllRef}
                      type="checkbox"
                      aria-label="Select all visible proxies"
                      checked={allVisibleSelected}
                      onChange={(event) => toggleVisibleSelection(event.target.checked)}
                    />
                  </th>
                  <th className="px-3 py-2">Name</th>
                  <th className="px-3 py-2">Country</th>
                  <th className="px-3 py-2">Plan</th>
                  <th className="px-3 py-2">Status</th>
                  <th className="px-3 py-2">Order</th>
                  <th className="px-3 py-2">Updated</th>
                  <th className="px-3 py-2">Actions</th>
                </tr>
              </thead>
              <tbody>
                {data.items.map((proxy) => (
                  <tr key={proxy.id} className="border-t border-slate-100">
                    <td className="px-3 py-2">
                      <input
                        type="checkbox"
                        aria-label={`Select ${proxy.name}`}
                        checked={selectedIdSet.has(proxy.id)}
                        onChange={(event) => toggleRowSelection(proxy.id, event.target.checked)}
                      />
                    </td>
                    <td className="px-3 py-2">{proxy.name}</td>
                    <td className="px-3 py-2"><Badge label={`${proxy.country} (${proxy.countryCode})`} tone="blue" /></td>
                    <td className="px-3 py-2"><Badge label={proxy.isPremium ? "Premium" : "Free"} tone={proxy.isPremium ? "yellow" : "green"} /></td>
                    <td className="px-3 py-2"><Badge label={proxy.status} tone={proxy.status === "active" ? "green" : "gray"} /></td>
                    <td className="px-3 py-2">{proxy.sortOrder}</td>
                    <td className="px-3 py-2">{new Date(proxy.updatedAt).toLocaleString()}</td>
                    <td className="px-3 py-2">
                      <div className="flex flex-wrap gap-2">
                        <Link href={`/proxies/${proxy.id}/edit`} className="text-brand-700 underline">Edit</Link>
                        <Button disabled={bulkBusy} variant="secondary" onClick={() => onToggleStatus(proxy.id, proxy.status === "active" ? "inactive" : "active")}>{proxy.status === "active" ? "Deactivate" : "Activate"}</Button>
                        <Button disabled={bulkBusy} variant="danger" onClick={() => onDelete(proxy.id)}>Delete</Button>
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
