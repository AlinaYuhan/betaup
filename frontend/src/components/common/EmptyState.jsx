export default function EmptyState({ title, description }) {
  return (
    <div className="rounded-3xl border border-dashed border-white/15 bg-white/5 p-8 text-center">
      <h3 className="text-lg font-semibold text-white">{title}</h3>
      <p className="mt-3 text-sm leading-7 text-slate-400">{description}</p>
    </div>
  );
}
