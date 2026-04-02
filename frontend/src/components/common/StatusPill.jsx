export default function StatusPill({ label, tone = "info" }) {
  const toneClass =
    tone === "warm"
      ? "border-amber-400/30 bg-amber-400/10 text-amber-200"
      : tone === "success"
        ? "border-emerald-400/30 bg-emerald-400/10 text-emerald-200"
        : "border-ice/20 bg-ice/10 text-ice";

  return (
    <span className={`inline-flex rounded-full border px-3 py-1 text-xs font-semibold uppercase tracking-[0.2em] ${toneClass}`}>
      {label}
    </span>
  );
}
