export default function SectionCard({ title, kicker, children, action }) {
  return (
    <section className="section-card">
      <div className="mb-5 flex flex-wrap items-start justify-between gap-4">
        <div>
          {kicker ? <span className="eyebrow">{kicker}</span> : null}
          <h2 className="text-xl font-semibold text-white">{title}</h2>
        </div>
        {action}
      </div>
      {children}
    </section>
  );
}
