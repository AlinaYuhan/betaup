import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import api from "../../api/axios";
import EmptyState from "../../components/common/EmptyState";
import LoadingState from "../../components/common/LoadingState";
import PaginationControls from "../../components/common/PaginationControls";
import SectionCard from "../../components/common/SectionCard";
import StatusPill from "../../components/common/StatusPill";
import { getApiErrorMessage } from "../../utils/api";
import { buildCollectionParams, parseSortValue } from "../../utils/collections";

export default function ClimbLogsPage() {
  const [logPage, setLogPage] = useState({
    items: [],
    totalElements: 0,
    totalPages: 0,
    page: 0,
    hasNext: false,
    hasPrevious: false,
  });
  const [error, setError] = useState("");
  const [isLoading, setIsLoading] = useState(true);
  const [deletingId, setDeletingId] = useState(null);
  const [page, setPage] = useState(0);
  const [sort, setSort] = useState("date:desc");

  useEffect(() => {
    async function loadClimbs() {
      setIsLoading(true);
      setError("");
      try {
        const { sortBy, sortDir } = parseSortValue(sort, "date:desc");
        const params = buildCollectionParams({
          page,
          size: 6,
          sortBy,
          sortDir,
        });
        const response = await api.get(`/climbs?${params.toString()}`);
        setLogPage(response.data.data);
      } catch (requestError) {
        setError(getApiErrorMessage(requestError, "Failed to load climb logs."));
      } finally {
        setIsLoading(false);
      }
    }

    loadClimbs();
  }, [page, sort]);

  const handleDelete = async (climbId) => {
    const confirmed = window.confirm("Delete this climb log? Logs with coach feedback cannot be deleted.");
    if (!confirmed) {
      return;
    }

    setError("");
    setDeletingId(climbId);
    try {
      await api.delete(`/climbs/${climbId}`);
      setLogPage((current) => ({
        ...current,
        items: current.items.filter((log) => log.id !== climbId),
        totalElements: Math.max(current.totalElements - 1, 0),
      }));
    } catch (requestError) {
      setError(getApiErrorMessage(requestError, "Failed to delete climb log."));
    } finally {
      setDeletingId(null);
    }
  };

  return (
    <div className="grid gap-4">
      <SectionCard
        title="Climb log library"
        kicker="Route list"
        action={
          <div className="flex flex-wrap items-center gap-3">
            <select
              className="field-input w-full sm:w-48"
              value={sort}
              onChange={(event) => {
                setPage(0);
                setSort(event.target.value);
              }}
            >
              <option value="date:desc">Newest session date</option>
              <option value="date:asc">Oldest session date</option>
              <option value="createdAt:desc">Recently created</option>
              <option value="routeName:asc">Route name A-Z</option>
              <option value="difficulty:asc">Difficulty A-Z</option>
            </select>
            <StatusPill label={`${logPage.totalElements} entries`} />
          </div>
        }
      >
        {isLoading ? <LoadingState label="Loading climbs" /> : null}
        {!isLoading && error && !logPage.items.length ? <EmptyState title="Climb logs unavailable" description={error} /> : null}
        {!isLoading && error && logPage.items.length ? (
          <div className="rounded-2xl border border-rose-400/20 bg-rose-400/10 px-4 py-3 text-sm text-rose-200">{error}</div>
        ) : null}
        {!isLoading && !error && !logPage.items.length ? (
          <EmptyState title="No climbs yet" description="Create your first climb log to start building your session history." />
        ) : null}
        {!isLoading && !error && logPage.items.length ? (
          <div className="grid gap-3">
            {logPage.items.map((log) => (
              <article key={log.id} className="rounded-2xl border border-white/10 bg-white/5 p-5">
                <div className="flex flex-wrap items-center justify-between gap-4">
                  <div>
                    <h3 className="text-lg font-semibold text-white">{log.routeName}</h3>
                    <p className="mt-1 text-sm text-slate-400">
                      {log.difficulty} at {log.venue}
                    </p>
                    <p className="mt-2 text-xs uppercase tracking-[0.2em] text-slate-500">{log.date}</p>
                  </div>
                  <div className="flex flex-wrap items-center gap-3">
                    <StatusPill label={log.status} tone={log.status === "COMPLETED" ? "success" : "warm"} />
                    <Link className="secondary-button" to={`/climber/climbs/new?edit=${log.id}`}>
                      Edit
                    </Link>
                    <button
                      type="button"
                      className="rounded-2xl border border-rose-400/20 bg-rose-400/10 px-4 py-3 text-sm font-semibold text-rose-200 transition hover:bg-rose-400/20 disabled:cursor-not-allowed disabled:opacity-60"
                      disabled={deletingId === log.id}
                      onClick={() => handleDelete(log.id)}
                    >
                      {deletingId === log.id ? "Deleting..." : "Delete"}
                    </button>
                  </div>
                </div>
                {log.notes ? <p className="mt-4 text-sm leading-7 text-slate-300">{log.notes}</p> : null}
              </article>
            ))}
            <PaginationControls
              page={logPage.page}
              totalPages={logPage.totalPages}
              hasNext={logPage.hasNext}
              hasPrevious={logPage.hasPrevious}
              onPageChange={setPage}
            />
          </div>
        ) : null}
      </SectionCard>

      <SectionCard title="Round 6 status" kicker="Collections">
        <p className="text-sm leading-7 text-slate-300">
          Climb logs now use the same paged and sortable collection pattern as feedback history and coach roster views.
        </p>
      </SectionCard>
    </div>
  );
}
