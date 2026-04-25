export function parsePagination(page?: string, limit?: string): { page: number; limit: number; skip: number } {
  const p = Number(page ?? 1);
  const l = Number(limit ?? 20);

  const normalizedPage = Number.isFinite(p) && p > 0 ? Math.floor(p) : 1;
  const normalizedLimit = Number.isFinite(l) && l > 0 ? Math.min(Math.floor(l), 100) : 20;

  return {
    page: normalizedPage,
    limit: normalizedLimit,
    skip: (normalizedPage - 1) * normalizedLimit,
  };
}
