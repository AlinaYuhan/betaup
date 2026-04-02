import { NavLink } from "react-router-dom";

export default function SidebarNav({ navigation }) {
  return (
    <aside className="glass-panel flex h-full flex-col gap-6 p-5">
      <div>
        <p className="font-display text-4xl uppercase tracking-[0.12em] text-ember">BetaUp</p>
        <p className="mt-2 text-sm text-slate-400">Round 4 MVP slice with live auth, feedback management, and climb workflows.</p>
      </div>

      <nav className="flex flex-1 flex-col gap-2">
        {navigation.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            className={({ isActive }) =>
              [
                "rounded-2xl border px-4 py-3 transition",
                isActive
                  ? "border-ember/60 bg-ember/10 text-white"
                  : "border-white/5 bg-white/0 text-slate-300 hover:border-ice/20 hover:bg-white/5",
              ].join(" ")
            }
          >
            <span className="block text-sm font-semibold">{item.label}</span>
            <span className="mt-1 block text-xs uppercase tracking-[0.18em] text-slate-500">{item.helper}</span>
          </NavLink>
        ))}
      </nav>
    </aside>
  );
}
