import { Button } from "./Button";

export function Pagination({
  page,
  totalPages,
  onPage,
}: {
  page: number;
  totalPages: number;
  onPage: (page: number) => void;
}) {
  return (
    <div className="flex items-center justify-end gap-2">
      <Button variant="secondary" onClick={() => onPage(Math.max(page - 1, 1))} disabled={page <= 1}>
        Prev
      </Button>
      <span className="text-sm text-slate-600">
        {page} / {Math.max(totalPages, 1)}
      </span>
      <Button
        variant="secondary"
        onClick={() => onPage(Math.min(page + 1, totalPages))}
        disabled={page >= totalPages}
      >
        Next
      </Button>
    </div>
  );
}
