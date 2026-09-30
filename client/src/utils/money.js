export function formatCents(cents) {
  return (cents / 100).toLocaleString(undefined, { style: "currency", currency: "USD" });
}
