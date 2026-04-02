export default function ActivityFeed({ items, emptyTitle, emptyDescription }) {
  if (!items?.length) {
    return (
      <div className="rounded-3xl border border-dashed border-white/15 bg-white/5 p-8 text-center">
        <h3 className="text-lg font-semibold text-white">{emptyTitle}</h3>
        <p className="mt-3 text-sm leading-7 text-slate-400">{emptyDescription}</p>
      </div>
    );
  }

  return (
    <div className="space-y-3">
      {items.map((item) => (
        <article key={`${item.title}-${item.meta}`} className="rounded-2xl border border-white/10 bg-white/5 p-4">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <div>
              <h3 className="text-base font-semibold text-white">{item.title}</h3>
              <p className="mt-1 text-sm text-slate-400">{item.subtitle}</p>
            </div>
            <span className="rounded-full border border-white/10 bg-white/5 px-3 py-1 text-xs uppercase tracking-[0.2em] text-slate-300">
              {item.meta}
            </span>
          </div>
        </article>
      ))}
    </div>
  );
}
