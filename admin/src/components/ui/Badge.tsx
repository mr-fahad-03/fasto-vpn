import clsx from "clsx";

export function Badge({
  label,
  tone = "gray",
}: {
  label: string;
  tone?: "gray" | "green" | "yellow" | "red" | "blue";
}) {
  return (
    <span
      className={clsx(
        "inline-flex rounded-full px-2 py-1 text-xs font-semibold",
        tone === "gray" && "bg-slate-200 text-slate-700",
        tone === "green" && "bg-emerald-100 text-emerald-700",
        tone === "yellow" && "bg-amber-100 text-amber-700",
        tone === "red" && "bg-red-100 text-red-700",
        tone === "blue" && "bg-blue-100 text-blue-700",
      )}
    >
      {label}
    </span>
  );
}
