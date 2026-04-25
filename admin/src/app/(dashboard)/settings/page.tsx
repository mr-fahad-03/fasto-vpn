"use client";

import { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { settingsSchema, type SettingsInput } from "@/lib/schemas";
import { api } from "@/lib/client-api";
import type { AdminSettings } from "@/lib/types";
import { PageHeader } from "@/components/common/PageHeader";
import { LoadingState, ErrorState } from "@/components/common/States";
import { Input } from "@/components/ui/Input";
import { TextArea } from "@/components/ui/TextArea";
import { Button } from "@/components/ui/Button";

export default function SettingsPage() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [saved, setSaved] = useState<string | null>(null);

  const form = useForm<SettingsInput>({
    resolver: zodResolver(settingsSchema),
    defaultValues: {
      freePlanAdsEnabled: true,
      maxFreeProxiesCount: 20,
      featuredCountries: "",
      appNotices: "",
    },
  });

  useEffect(() => {
    (async () => {
      setLoading(true);
      setError(null);
      try {
        const data = await api.getSettings();
        form.reset({
          freePlanAdsEnabled: data.freePlanAdsEnabled,
          maxFreeProxiesCount: data.maxFreeProxiesCount,
          featuredCountries: data.featuredCountries.join(", "),
          appNotices: data.appNotices.join("\n"),
        });
      } catch (fetchError) {
        setError(fetchError instanceof Error ? fetchError.message : "Failed to load settings");
      } finally {
        setLoading(false);
      }
    })();
  }, [form]);

  const onSubmit = form.handleSubmit(async (values) => {
    setSaved(null);
    setError(null);

    const payload: AdminSettings = {
      freePlanAdsEnabled: values.freePlanAdsEnabled,
      maxFreeProxiesCount: values.maxFreeProxiesCount,
      featuredCountries: values.featuredCountries
        .split(",")
        .map((x) => x.trim().toUpperCase())
        .filter(Boolean),
      appNotices: values.appNotices
        .split("\n")
        .map((x) => x.trim())
        .filter(Boolean),
    };

    try {
      await api.updateSettings(payload);
      setSaved("Settings updated successfully.");
    } catch (submitError) {
      setError(submitError instanceof Error ? submitError.message : "Failed to update settings");
    }
  });

  if (loading) return <LoadingState label="Loading settings..." />;
  if (error && !form.formState.isDirty) return <ErrorState message={error} />;

  return (
    <div className="space-y-4">
      <PageHeader title="Settings" description="Manage free plan flags, featured countries, and app notices." />

      <form onSubmit={onSubmit} className="space-y-4 rounded-xl border border-slate-200 bg-white p-5">
        <label className="inline-flex items-center gap-2 text-sm text-slate-700">
          <input type="checkbox" {...form.register("freePlanAdsEnabled")} />
          Ads enabled for free plan
        </label>

        <Input
          label="Max free proxies count"
          type="number"
          error={form.formState.errors.maxFreeProxiesCount?.message}
          {...form.register("maxFreeProxiesCount")}
        />

        <Input
          label="Featured countries (comma separated ISO2)"
          error={form.formState.errors.featuredCountries?.message}
          {...form.register("featuredCountries")}
        />

        <TextArea
          label="App notices (one per line)"
          rows={6}
          error={form.formState.errors.appNotices?.message}
          {...form.register("appNotices")}
        />

        {saved && <div className="text-sm text-emerald-700">{saved}</div>}
        {error && <div className="text-sm text-red-600">{error}</div>}

        <Button type="submit" disabled={form.formState.isSubmitting}>
          {form.formState.isSubmitting ? "Saving..." : "Save Settings"}
        </Button>
      </form>
    </div>
  );
}
