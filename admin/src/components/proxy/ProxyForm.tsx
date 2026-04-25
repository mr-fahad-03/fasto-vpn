"use client";

import { useState } from "react";
import { zodResolver } from "@hookform/resolvers/zod";
import { useForm } from "react-hook-form";
import { proxyFormSchema, type ProxyFormInput } from "@/lib/schemas";
import { api } from "@/lib/client-api";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { Select } from "@/components/ui/Select";
import { Badge } from "@/components/ui/Badge";
import { useRouter } from "next/navigation";
import type { ProxyItem } from "@/lib/types";

export function ProxyForm({ mode, initial }: { mode: "create" | "edit"; initial?: ProxyItem }) {
  const router = useRouter();
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [detectedCountry, setDetectedCountry] = useState<string | null>(null);

  const form = useForm<ProxyFormInput>({
    resolver: zodResolver(proxyFormSchema),
    defaultValues: {
      name: initial?.name ?? "",
      host: initial?.host ?? "",
      port: initial?.port ?? 8080,
      type: initial?.type ?? "HTTP",
      username: initial?.username ?? "",
      password: initial?.password ?? "",
      isPremium: initial?.isPremium ?? false,
      status: initial?.status ?? "active",
      sortOrder: initial?.sortOrder ?? 0,
      tags: initial?.tags?.join(", ") ?? "",
      maxFreeVisible: initial?.maxFreeVisible ?? true,
      latency: initial?.latency ?? 0,
      healthStatus: initial?.healthStatus ?? "unknown",
    },
  });

  const onSubmit = form.handleSubmit(async (values) => {
    setSubmitError(null);
    try {
      const payload = {
        ...values,
        username: values.username?.trim() || undefined,
        password: values.password?.trim() || undefined,
        tags: values.tags
          .split(",")
          .map((x) => x.trim())
          .filter(Boolean),
      };

      const result =
        mode === "create"
          ? await api.createProxy(payload)
          : await api.updateProxy(initial!.id, payload);

      setDetectedCountry(`${result.country} (${result.countryCode})`);
      router.push("/proxies");
      router.refresh();
    } catch (error) {
      setSubmitError(error instanceof Error ? error.message : "Save failed");
    }
  });

  return (
    <form onSubmit={onSubmit} className="space-y-4 rounded-xl border border-slate-200 bg-white p-5">
      <div className="grid gap-4 md:grid-cols-2">
        <Input label="Name" error={form.formState.errors.name?.message} {...form.register("name")} />
        <Input label="Host / IP" error={form.formState.errors.host?.message} {...form.register("host")} />
        <Input label="Port" type="number" error={form.formState.errors.port?.message} {...form.register("port")} />
        <Select
          label="Type"
          options={[
            { label: "HTTP", value: "HTTP" },
            { label: "SOCKS5", value: "SOCKS5" },
          ]}
          error={form.formState.errors.type?.message}
          {...form.register("type")}
        />
        <Input label="Username (optional)" error={form.formState.errors.username?.message} {...form.register("username")} />
        <Input label="Password (optional)" type="password" error={form.formState.errors.password?.message} {...form.register("password")} />
        <Select
          label="Status"
          options={[
            { label: "Active", value: "active" },
            { label: "Inactive", value: "inactive" },
          ]}
          error={form.formState.errors.status?.message}
          {...form.register("status")}
        />
        <Input label="Sort Order" type="number" error={form.formState.errors.sortOrder?.message} {...form.register("sortOrder")} />
        <Input label="Latency" type="number" error={form.formState.errors.latency?.message} {...form.register("latency")} />
        <Select
          label="Health Status"
          options={[
            { label: "Unknown", value: "unknown" },
            { label: "Healthy", value: "healthy" },
            { label: "Degraded", value: "degraded" },
            { label: "Down", value: "down" },
          ]}
          error={form.formState.errors.healthStatus?.message}
          {...form.register("healthStatus")}
        />
        <Input label="Tags (comma separated)" error={form.formState.errors.tags?.message} {...form.register("tags")} />
      </div>

      <div className="flex flex-wrap gap-4">
        <label className="inline-flex items-center gap-2 text-sm text-slate-700">
          <input type="checkbox" {...form.register("isPremium")} />
          Premium proxy
        </label>
        <label className="inline-flex items-center gap-2 text-sm text-slate-700">
          <input type="checkbox" {...form.register("maxFreeVisible")} />
          Visible in free list
        </label>
      </div>

      {detectedCountry && (
        <div className="text-sm text-slate-700">
          Detected country: <Badge label={detectedCountry} tone="blue" />
        </div>
      )}

      {submitError && <div className="text-sm text-red-600">{submitError}</div>}

      <div className="flex gap-2">
        <Button type="submit" disabled={form.formState.isSubmitting}>
          {form.formState.isSubmitting ? "Saving..." : mode === "create" ? "Create Proxy" : "Update Proxy"}
        </Button>
        <Button type="button" variant="secondary" onClick={() => router.push("/proxies")}>Back</Button>
      </div>
    </form>
  );
}
