import { useEffect, useState } from "react";
import api from "../../api/axios";
import ActivityFeed from "../../components/common/ActivityFeed";
import EmptyState from "../../components/common/EmptyState";
import LoadingState from "../../components/common/LoadingState";
import MetricBarChart from "../../components/common/MetricBarChart";
import ProgressList from "../../components/common/ProgressList";
import SectionCard from "../../components/common/SectionCard";
import StatusPill from "../../components/common/StatusPill";
import { useAuth } from "../../hooks/useAuth";
import { getApiErrorMessage } from "../../utils/api";
import { dashboardRangeOptions, resolveDownloadFilename, triggerFileDownload } from "../../utils/dashboard";

export default function ClimberDashboardPage() {
  const { user } = useAuth();
  const [dashboard, setDashboard] = useState(null);
  const [error, setError] = useState("");
  const [actionError, setActionError] = useState("");
  const [isLoading, setIsLoading] = useState(true);
  const [isExporting, setIsExporting] = useState(false);
  const [range, setRange] = useState("LAST_180_DAYS");

  useEffect(() => {
    async function loadDashboard() {
      setIsLoading(true);
      setError("");
      setActionError("");
      try {
        const response = await api.get(`/dashboard?range=${range}`);
        setDashboard(response.data.data);
      } catch (requestError) {
        setError(getApiErrorMessage(requestError, "Failed to load dashboard."));
      } finally {
        setIsLoading(false);
      }
    }

    loadDashboard();
  }, [range]);

  const handleExport = async () => {
    setIsExporting(true);
    setActionError("");
    try {
      const response = await api.get(`/dashboard/export?range=${range}`, { responseType: "blob" });
      triggerFileDownload(response.data, resolveDownloadFilename(response.headers, `betaup-dashboard-${range.toLowerCase()}.csv`));
    } catch (requestError) {
      setActionError(getApiErrorMessage(requestError, "Failed to export dashboard."));
    } finally {
      setIsExporting(false);
    }
  };

  if (isLoading) {
    return <LoadingState label="Loading dashboard" />;
  }

  if (error) {
    return <EmptyState title="Dashboard unavailable" description={error} />;
  }

  return (
    <div className="grid gap-4">
      <section className="glass-panel overflow-hidden p-6 sm:p-8">
        <div className="flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
          <div>
            <span className="eyebrow">Climber Dashboard</span>
            <h2 className="max-w-2xl text-3xl font-semibold text-white sm:text-4xl">
              {dashboard?.title || `Welcome back, ${user?.name ?? "Climber"}.`}
            </h2>
            <p className="mt-4 max-w-2xl text-sm leading-7 text-slate-300">{dashboard?.summary}</p>
          </div>
          <div className="flex flex-wrap items-center gap-3">
            <select className="field-input w-full sm:w-48" value={range} onChange={(event) => setRange(event.target.value)}>
              {dashboardRangeOptions.map((option) => (
                <option key={option.value} value={option.value}>
                  {option.label}
                </option>
              ))}
            </select>
            <button
              type="button"
              className="secondary-button disabled:cursor-not-allowed disabled:opacity-60"
              disabled={isExporting}
              onClick={handleExport}
            >
              {isExporting ? "Exporting..." : "Export CSV"}
            </button>
            <StatusPill label={dashboard?.rangeLabel || dashboard?.audience || "CLIMBER"} tone="success" />
          </div>
        </div>

        <div className="mt-8 grid gap-4 md:grid-cols-2 xl:grid-cols-4">
          {(dashboard?.metrics ?? []).map((metric, index) => (
            <div key={metric.label} className="stat-tile">
              <StatusPill label={metric.label} tone={index === 0 ? "success" : index === 1 ? "warm" : "info"} />
              <p className="mt-4 text-3xl font-semibold text-white">{metric.value}</p>
              <p className="mt-2 text-sm text-slate-400">{metric.helper}</p>
            </div>
          ))}
        </div>

        {actionError ? (
          <div className="mt-6 rounded-2xl border border-rose-400/20 bg-rose-400/10 px-4 py-3 text-sm text-rose-200">{actionError}</div>
        ) : null}
      </section>

      <div className="grid gap-4 xl:grid-cols-2">
        <SectionCard title="Performance breakdown" kicker="Distribution">
          <ProgressList items={dashboard?.breakdown ?? []} formatter={(value) => `${value}`} />
        </SectionCard>

        <SectionCard title="Recent activity" kicker="Feed">
          <ActivityFeed
            items={dashboard?.recentActivity ?? []}
            emptyTitle="No recent activity"
            emptyDescription="Create climbs or receive coach feedback to populate your dashboard feed."
          />
        </SectionCard>
      </div>

      <div className="grid gap-4 xl:grid-cols-3">
        {(dashboard?.charts ?? []).map((chart) => (
          <SectionCard key={chart.title} title={chart.title} kicker="Chart">
            <p className="mb-4 text-sm leading-7 text-slate-400">{chart.subtitle}</p>
            <MetricBarChart points={chart.points} />
          </SectionCard>
        ))}
      </div>

      <SectionCard title="Current highlights" kicker="Live data">
        <ul className="grid gap-3 xl:grid-cols-3">
          {(dashboard?.highlights ?? []).map((item) => (
            <li key={item} className="rounded-2xl border border-white/10 bg-white/5 p-4 text-sm leading-7 text-slate-300">
              {item}
            </li>
          ))}
        </ul>
      </SectionCard>
    </div>
  );
}
