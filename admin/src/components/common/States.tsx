export function LoadingState({ label = "Loading..." }: { label?: string }) {
  return <div className="rounded-lg border border-slate-200 bg-white p-6 text-sm text-slate-600">{label}</div>;
}

export function EmptyState({ label = "No data found." }: { label?: string }) {
  return <div className="rounded-lg border border-dashed border-slate-300 bg-white p-6 text-sm text-slate-500">{label}</div>;
}

export function ErrorState({ message }: { message: string }) {
  return <div className="rounded-lg border border-red-200 bg-red-50 p-4 text-sm text-red-700">{message}</div>;
}
