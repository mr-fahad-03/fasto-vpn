import { SelectHTMLAttributes } from "react";
import clsx from "clsx";

type SelectProps = SelectHTMLAttributes<HTMLSelectElement> & {
  label?: string;
  error?: string;
  options: Array<{ label: string; value: string }>;
};

export function Select({ label, error, className, options, ...props }: SelectProps) {
  return (
    <label className="block w-full">
      {label && <span className="mb-1 block text-sm font-medium text-slate-700">{label}</span>}
      <select
        className={clsx(
          "w-full rounded-md border px-3 py-2 text-sm focus:outline-none",
          error ? "border-red-400 focus:ring-2 focus:ring-red-200" : "border-slate-300 focus:ring-2 focus:ring-brand-200",
          className,
        )}
        {...props}
      >
        {options.map((option) => (
          <option key={option.value} value={option.value}>
            {option.label}
          </option>
        ))}
      </select>
      {error && <span className="mt-1 block text-xs text-red-600">{error}</span>}
    </label>
  );
}
