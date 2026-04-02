import { Outlet } from "react-router-dom";
import { useAuth } from "../../hooks/useAuth";
import SidebarNav from "./SidebarNav";

export default function AuthenticatedLayout({ areaLabel, navigation }) {
  const { user, logout } = useAuth();

  return (
    <div className="app-shell min-h-screen px-4 py-4 sm:px-6 lg:px-8">
      <div className="mx-auto grid min-h-[calc(100vh-2rem)] max-w-7xl gap-4 lg:grid-cols-[290px_1fr]">
        <SidebarNav navigation={navigation} />

        <div className="flex min-h-full flex-col gap-4">
          <header className="glass-panel flex flex-wrap items-center justify-between gap-4 px-6 py-5">
            <div>
              <p className="text-xs uppercase tracking-[0.3em] text-slate-500">{areaLabel}</p>
              <h1 className="mt-2 text-3xl font-semibold text-white">BetaUp Control Surface</h1>
            </div>

            <div className="flex items-center gap-3">
              <div className="rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-right">
                <p className="text-sm font-semibold text-white">{user?.name ?? "Guest"}</p>
                <p className="text-xs uppercase tracking-[0.18em] text-slate-500">{user?.role ?? "Unknown"}</p>
              </div>
              <button type="button" className="secondary-button" onClick={logout}>
                Log Out
              </button>
            </div>
          </header>

          <main className="flex-1">
            <Outlet />
          </main>
        </div>
      </div>
    </div>
  );
}
