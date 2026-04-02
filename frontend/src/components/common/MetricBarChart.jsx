export default function MetricBarChart({ points = [], valueSuffix = "" }) {
  if (!points.length) {
    return (
      <div className="rounded-2xl border border-dashed border-white/15 bg-white/5 p-6 text-sm leading-7 text-slate-400">
        Not enough activity yet to render this chart.
      </div>
    );
  }

  const maxValue = Math.max(...points.map((point) => point.value), 1);

  return (
    <div className="space-y-4">
      {points.map((point) => (
        <div key={`${point.label}-${point.value}`} className="rounded-2xl border border-white/10 bg-white/5 p-4">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <div>
              <p className="text-sm font-semibold text-white">{point.label}</p>
              <p className="mt-1 text-xs uppercase tracking-[0.18em] text-slate-500">{point.helper}</p>
            </div>
            <p className="text-sm font-semibold text-ice">
              {point.value}
              {valueSuffix}
            </p>
          </div>
          <div className="mt-4 h-2 rounded-full bg-white/10">
            <div
              className="h-2 rounded-full bg-gradient-to-r from-ember via-orange-300 to-ice"
              style={{ width: `${point.value === 0 ? 0 : Math.max(8, Math.round((point.value / maxValue) * 100))}%` }}
            />
          </div>
        </div>
      ))}
    </div>
  );
}
