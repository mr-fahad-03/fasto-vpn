"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { loginSchema, type LoginInput } from "@/lib/schemas";
import { api } from "@/lib/client-api";
import { Input } from "@/components/ui/Input";
import { Button } from "@/components/ui/Button";

export default function LoginPage() {
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);

  const form = useForm<LoginInput>({
    resolver: zodResolver(loginSchema),
    defaultValues: {
      email: "admin@fastovpn.com",
      password: "Admin@12345",
    },
  });

  const onSubmit = form.handleSubmit(async (values) => {
    setError(null);
    try {
      await api.login(values.email, values.password);
      router.push("/dashboard");
      router.refresh();
    } catch (submitError) {
      setError(submitError instanceof Error ? submitError.message : "Login failed");
    }
  });

  return (
    <main className="flex min-h-screen items-center justify-center px-4">
      <form className="w-full max-w-md space-y-4 rounded-xl border border-slate-200 bg-white p-6" onSubmit={onSubmit}>
        <h1 className="text-2xl font-semibold text-slate-900">Fasto VPN Admin</h1>
        <p className="text-sm text-slate-500">Sign in to manage proxies, users, and subscriptions.</p>

        <Input label="Email" error={form.formState.errors.email?.message} {...form.register("email")} />
        <Input
          label="Password"
          type="password"
          error={form.formState.errors.password?.message}
          {...form.register("password")}
        />

        {error && <div className="text-sm text-red-600">{error}</div>}

        <Button className="w-full" type="submit" disabled={form.formState.isSubmitting}>
          {form.formState.isSubmitting ? "Signing in..." : "Sign in"}
        </Button>
      </form>
    </main>
  );
}
