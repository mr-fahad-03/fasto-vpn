"use client";

import { useEffect, useMemo, useState } from "react";
import { api } from "@/lib/client-api";
import type { Paginated, UserItem } from "@/lib/types";
import { TABLE_PAGE_SIZE } from "@/lib/constants";
import { PageHeader } from "@/components/common/PageHeader";
import { LoadingState, ErrorState, EmptyState } from "@/components/common/States";
import { Input } from "@/components/ui/Input";
import { Select } from "@/components/ui/Select";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Pagination } from "@/components/ui/Pagination";

export default function UsersPage() {
  const [data, setData] = useState<Paginated<UserItem> | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [page, setPage] = useState(1);
  const [search, setSearch] = useState("");
  const [mode, setMode] = useState("");
  const [isActive, setIsActive] = useState("");

  const query = useMemo(
    () => ({ page, limit: TABLE_PAGE_SIZE, search, mode, isActive, sortBy: "updatedAt", sortOrder: "desc" }),
    [page, search, mode, isActive],
  );

  const fetchData = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await api.listUsers(query);
      setData(response);
    } catch (fetchError) {
      setError(fetchError instanceof Error ? fetchError.message : "Failed to load users");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void fetchData();
  }, [page, search, mode, isActive]);

  async function onToggle(user: UserItem) {
    await api.updateUserStatus(user.id, !user.isActive);
    await fetchData();
  }

  return (
    <div className="space-y-4">
      <PageHeader title="Users" description="Manage guest and mobile authenticated users." />

      <div className="grid gap-3 rounded-xl border border-slate-200 bg-white p-4 md:grid-cols-4">
        <Input placeholder="Search email/firebase/guest id" value={search} onChange={(e) => { setSearch(e.target.value); setPage(1); }} />
        <Select value={mode} onChange={(e) => { setMode(e.target.value); setPage(1); }} options={[{label:"All Modes",value:""},{label:"Guest",value:"guest"},{label:"Mobile",value:"mobile"}]} />
        <Select value={isActive} onChange={(e) => { setIsActive(e.target.value); setPage(1); }} options={[{label:"All Status",value:""},{label:"Active",value:"true"},{label:"Inactive",value:"false"}]} />
        <Button variant="secondary" onClick={() => { setSearch(""); setMode(""); setIsActive(""); setPage(1); }}>Reset</Button>
      </div>

      {loading && <LoadingState label="Loading users..." />}
      {error && <ErrorState message={error} />}
      {!loading && !error && data && data.items.length === 0 && <EmptyState label="No users found." />}

      {!loading && !error && data && data.items.length > 0 && (
        <div className="space-y-3">
          <div className="overflow-x-auto rounded-xl border border-slate-200 bg-white">
            <table className="min-w-full text-left text-sm">
              <thead className="bg-slate-100 text-slate-700">
                <tr>
                  <th className="px-3 py-2">Type</th>
                  <th className="px-3 py-2">Email / ID</th>
                  <th className="px-3 py-2">Status</th>
                  <th className="px-3 py-2">Last Seen</th>
                  <th className="px-3 py-2">Actions</th>
                </tr>
              </thead>
              <tbody>
                {data.items.map((user) => (
                  <tr key={user.id} className="border-t border-slate-100">
                    <td className="px-3 py-2"><Badge label={user.mode} tone="blue" /></td>
                    <td className="px-3 py-2">
                      <div>{user.email ?? user.displayName ?? "-"}</div>
                      <div className="text-xs text-slate-500">{user.firebaseUid ?? user.guestSessionId ?? user.id}</div>
                    </td>
                    <td className="px-3 py-2"><Badge label={user.isActive ? "active" : "inactive"} tone={user.isActive ? "green" : "red"} /></td>
                    <td className="px-3 py-2">{user.lastSeenAt ? new Date(user.lastSeenAt).toLocaleString() : "-"}</td>
                    <td className="px-3 py-2">
                      <Button variant={user.isActive ? "danger" : "secondary"} onClick={() => onToggle(user)}>
                        {user.isActive ? "Deactivate" : "Activate"}
                      </Button>
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
