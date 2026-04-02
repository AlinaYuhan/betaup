export default function ProgressList({ items, formatter }) {
  const maxValue = Math.max(...items.map((item) => item.value), 1);

  return (
    <div className="space-y-4">
      {items.map((item) => {
        const basis = item.maxValue ?? maxValue;
        const width = Math.min(100, Math.round((item.value / Math.max(basis, 1)) * 100));

        return (
          <div key={item.label} className="rounded-2xl border border-white/10 bg-white/5 p-4">
            <div className="flex flex-wrap items-center justify-between gap-3">
              <div>
                <p className="text-sm font-semibold text-white">{item.label}</p>
                <p className="mt-1 text-xs uppercase tracking-[0.18em] text-slate-500">{item.helper}</p>
              </div>
              <p className="text-sm font-semibold text-ice">{formatter ? formatter(item.value) : item.value}</p>
            </div>
            <div className="mt-4 h-2 rounded-full bg-white/10">
              <div className="h-2 rounded-full bg-gradient-to-r from-ember to-ice" style={{ width: `${width}%` }} />
            </div>
          </div>
        );
      })}
    </div>
  );
}
