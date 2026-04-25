"use client";

import { useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { bulkImportSchema, type BulkImportInput } from "@/lib/schemas";
import { api } from "@/lib/client-api";
import { PageHeader } from "@/components/common/PageHeader";
import { TextArea } from "@/components/ui/TextArea";
import { Button } from "@/components/ui/Button";

const IMPORT_TEMPLATE = `# One proxy per line
# Format: host:port:type
# type must be HTTP or SOCKS5

130.61.174.200:1080:SOCKS5
147.45.60.34:1082:SOCKS5
13.230.49.39:8080:HTTP

# You can also use:
# 201.222.50.218:80
# http://201.222.50.218:80
# socks5://130.61.174.200:1080`;

export default function ProxyImportPage() {
  const [result, setResult] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const form = useForm<BulkImportInput>({
    resolver: zodResolver(bulkImportSchema),
    defaultValues: {
      rawText: "",
      isPremium: false,
    },
  });

  const onSubmit = form.handleSubmit(async (values) => {
    setResult(null);
    setError(null);

    try {
      const response = await api.bulkImportProxies(values.rawText, values.isPremium);
      setResult(`Imported ${response.imported} proxies successfully.`);
      form.reset({ rawText: "", isPremium: values.isPremium });
    } catch (submitError) {
      setError(submitError instanceof Error ? submitError.message : "Import failed");
    }
  });

  return (
    <div className="space-y-4">
      <PageHeader
        title="Bulk Import Proxies"
        description="Paste HTTP/SOCKS proxy lines in host:port, host:port:type, scheme://host:port, or table row format."
      />

      <form onSubmit={onSubmit} className="space-y-4 rounded-xl border border-slate-200 bg-white p-5">
        <TextArea
          label="Proxy Raw Text"
          rows={12}
          error={form.formState.errors.rawText?.message}
          placeholder={"47.251.74.38:1000\\n8.213.215.187 9080 TH Thailand\\nSOCKS5://8.8.8.8:1080"}
          {...form.register("rawText")}
        />

        <div className="flex flex-wrap gap-2">
          <Button
            type="button"
            variant="secondary"
            onClick={() => form.setValue("rawText", IMPORT_TEMPLATE, { shouldDirty: true, shouldValidate: true })}
          >
            Load Template
          </Button>
        </div>

        <div className="rounded-lg border border-slate-200 bg-slate-50 p-3 text-xs text-slate-700">
          Use one proxy per line. Recommended format: <code>host:port:type</code>. Remove website table headers and
          avoid invalid entries like <code>127.0.0.7</code> or <code>0.0.0.0</code>.
        </div>

        <label className="inline-flex items-center gap-2 text-sm text-slate-700">
          <input type="checkbox" {...form.register("isPremium")} />
          Import as premium proxies
        </label>

        {result && <div className="text-sm text-emerald-700">{result}</div>}
        {error && <div className="text-sm text-red-600">{error}</div>}

        <Button type="submit" disabled={form.formState.isSubmitting}>
          {form.formState.isSubmitting ? "Importing..." : "Import Proxies"}
        </Button>
      </form>
    </div>
  );
}
