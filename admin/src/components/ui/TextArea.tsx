import { TextareaHTMLAttributes } from "react";
import clsx from "clsx";

type TextAreaProps = TextareaHTMLAttributes<HTMLTextAreaElement> & {
  label?: string;
  error?: string;
};

export function TextArea({ label, error, className, ...props }: TextAreaProps) {
  return (
    <label className="block w-full">
      {label && <span className="mb-1 block text-sm font-medium text-slate-700">{label}</span>}
      <textarea
        className={clsx(
          "w-full rounded-md border px-3 py-2 text-sm focus:outline-none",
          error ? "border-red-400 focus:ring-2 focus:ring-red-200" : "border-slate-300 focus:ring-2 focus:ring-brand-200",
          className,
        )}
        {...props}
      />
      {error && <span className="mt-1 block text-xs text-red-600">{error}</span>}
    </label>
  );
}
