import { useDeferredValue, useEffect, useState } from "react";
import { Link } from "react-router-dom";
import api from "../../api/axios";
import EmptyState from "../../components/common/EmptyState";
import LoadingState from "../../components/common/LoadingState";
import PaginationControls from "../../components/common/PaginationControls";
import SectionCard from "../../components/common/SectionCard";
import StatusPill from "../../components/common/StatusPill";
import { getApiErrorMessage } from "../../utils/api";
import { buildCollectionParams, parseSortValue } from "../../utils/collections";

export default function ClimbersPage() {
  const [climberPage, setClimberPage] = useState({
    items: [],
    totalElements: 0,
    totalPages: 0,
    page: 0,
    hasNext: false,
    hasPrevious: false,
  });
  const [query, setQuery] = useState("");
  const [error, setError] = useState("");
  const [isLoading, setIsLoading] = useState(true);
  const [page, setPage] = useState(0);
  const [sort, setSort] = useState("createdAt:desc");
  const deferredQuery = useDeferredValue(query);

  useEffect(() => {
    async function loadClimbers() {
      setIsLoading(true);
      setError("");
      try {
        const { sortBy, sortDir } = parseSortValue(sort, "createdAt:desc");
        const params = buildCollectionParams({
          q: deferredQuery.trim(),
          page,
          size: 8,
          sortBy,
          sortDir,
        });
        const response = await api.get(`/coach/climbers?${params.toString()}`);
        setClimberPage(response.data.data);
      } catch (requestError) {
        setError(getApiErrorMessage(requestError, "Failed to load climbers."));
      } finally {
        setIsLoading(false);
      }
    }

    loadClimbers();
  }, [deferredQuery, page, sort]);

  return (
    <SectionCard
      title="Climber roster"
      kicker="Coach directory"
      action={
        <input
          className="field-input w-full sm:w-72"
          placeholder="Search name or email"
          value={query}
          onChange={(event) => {
            setPage(0);
            setQuery(event.target.value);
          }}
        />
      }
    >
      <div className="mb-5 flex flex-wrap items-center gap-3">
        <select
          className="field-input w-full sm:w-48"
          value={sort}
          onChange={(event) => {
            setPage(0);
            setSort(event.target.value);
          }}
        >
          <option value="createdAt:desc">Newest joined</option>
          <option value="name:asc">Name A-Z</option>
          <option value="name:desc">Name Z-A</option>
          <option value="email:asc">Email A-Z</option>
        </select>
        <StatusPill label={`${climberPage.totalElements} climbers`} tone="info" />
      </div>
      {isLoading ? <LoadingState label="Loading climbers" /> : null}
      {!isLoading && error ? <EmptyState title="Roster unavailable" description={error} /> : null}
      {!isLoading && !error && !climberPage.items.length ? (
        <EmptyState
          title={query ? "No climbers match this filter" : "No climbers yet"}
          description={query ? "Try a different search term." : "Register a climber account first, then they will appear in the coach roster."}
        />
      ) : null}
      {!isLoading && !error && climberPage.items.length ? (
        <div className="space-y-3">
          {climberPage.items.map((climber) => (
            <article key={climber.id} className="rounded-2xl border border-white/10 bg-white/5 p-5">
              <div className="flex flex-wrap items-center justify-between gap-4">
                <div>
                  <h3 className="text-lg font-semibold text-white">{climber.name}</h3>
                  <p className="mt-1 text-sm text-slate-400">{climber.email}</p>
                </div>
                <div className="flex items-center gap-3">
                  <StatusPill label={`${climber.climbCount} climbs`} tone="info" />
                  <StatusPill label={`${climber.feedbackCount} reviews`} tone="warm" />
                  <Link className="secondary-button" to={`/coach/climbers/${climber.id}`}>
                    Open Profile
                  </Link>
                </div>
              </div>
            </article>
          ))}
          <PaginationControls
            page={climberPage.page}
            totalPages={climberPage.totalPages}
            hasNext={climberPage.hasNext}
            hasPrevious={climberPage.hasPrevious}
            onPageChange={setPage}
          />
        </div>
      ) : null}
    </SectionCard>
  );
}
