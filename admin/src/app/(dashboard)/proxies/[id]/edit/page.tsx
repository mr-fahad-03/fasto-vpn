"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import type { ProxyItem } from "@/lib/types";
import { api } from "@/lib/client-api";
import { ProxyForm } from "@/components/proxy/ProxyForm";
import { PageHeader } from "@/components/common/PageHeader";
import { LoadingState, ErrorState } from "@/components/common/States";

export default function EditProxyPage() {
  const params = useParams<{ id: string }>();
  const [proxy, setProxy] = useState<ProxyItem | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    (async () => {
      setLoading(true);
      setError(null);
      try {
        const item = await api.getProxy(params.id);
        setProxy(item);
      } catch (fetchError) {
        setError(fetchError instanceof Error ? fetchError.message : "Failed to load proxy");
      } finally {
        setLoading(false);
      }
    })();
  }, [params.id]);

  if (loading) return <LoadingState label="Loading proxy..." />;
  if (error || !proxy) return <ErrorState message={error ?? "Proxy not found"} />;

  return (
    <div className="space-y-4">
      <PageHeader title="Edit Proxy" description="Update proxy server and metadata." />
      <ProxyForm mode="edit" initial={proxy} />
    </div>
  );
}
