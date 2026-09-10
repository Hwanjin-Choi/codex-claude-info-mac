export function tokenSummary(
  buckets: { startDate: string; tokens: number }[] | null | undefined,
  today = new Date()
): { yesterday: number; week: number } | undefined {
  if (!buckets) return undefined;
  const day = (date: Date) => `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
  const yesterday = new Date(today.getFullYear(), today.getMonth(), today.getDate() - 1);
  const weekStart = new Date(today.getFullYear(), today.getMonth(), today.getDate() - 6);
  return buckets.reduce((totals, bucket) => {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(bucket.startDate) || !Number.isFinite(bucket.tokens) || bucket.tokens < 0) return totals;
    if (bucket.startDate === day(yesterday)) totals.yesterday += bucket.tokens;
    if (bucket.startDate >= day(weekStart) && bucket.startDate <= day(today)) totals.week += bucket.tokens;
    return totals;
  }, { yesterday: 0, week: 0 });
}

export function escapeHtml(value: string): string {
  return value.replace(/[&<>"']/g, character => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#039;"
  })[character]!);
}
