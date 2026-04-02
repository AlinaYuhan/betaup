import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import api from "../../api/axios";
import EmptyState from "../../components/common/EmptyState";
import LoadingState from "../../components/common/LoadingState";
import PaginationControls from "../../components/common/PaginationControls";
import SectionCard from "../../components/common/SectionCard";
import StatusPill from "../../components/common/StatusPill";
import { getApiErrorMessage } from "../../utils/api";
import { buildCollectionParams, parseSortValue } from "../../utils/collections";

export default function CoachFeedbackPage() {
  const [feedbackPage, setFeedbackPage] = useState({
    items: [],
    totalElements: 0,
    totalPages: 0,
    page: 0,
    hasNext: false,
    hasPrevious: false,
  });
  const [climbers, setClimbers] = useState([]);
  const [filters, setFilters] = useState({ climberId: "", rating: "" });
  const [page, setPage] = useState(0);
  const [sort, setSort] = useState("createdAt:desc");
  const [isLoading, setIsLoading] = useState(true);
  const [isDeleting, setIsDeleting] = useState(null);
  const [error, setError] = useState("");

  useEffect(() => {
    async function bootstrap() {
      try {
        const climbersResponse = await api.get("/coach/climbers/options");
        setClimbers(climbersResponse.data.data);
      } catch (requestError) {
        setError(getApiErrorMessage(requestError, "Failed to load climber filters."));
      }
    }

    bootstrap();
  }, []);

  useEffect(() => {
    async function loadFeedback() {
      setIsLoading(true);
      setError("");

      try {
        const { sortBy, sortDir } = parseSortValue(sort, "createdAt:desc");
        const params = buildCollectionParams({
          climberId: filters.climberId,
          rating: filters.rating,
          page,
          size: 6,
          sortBy,
          sortDir,
        });

        const query = params.toString();
        const response = await api.get(query ? `/feedback?${query}` : "/feedback");
        setFeedbackPage(response.data.data);
      } catch (requestError) {
        setError(getApiErrorMessage(requestError, "Failed to load feedback list."));
      } finally {
        setIsLoading(false);
      }
    }

    loadFeedback();
  }, [filters, page, sort]);

  const summary = useMemo(
    () => ({
      total: feedbackPage.totalElements,
      average:
        feedbackPage.items.length > 0
          ? (feedbackPage.items.reduce((sum, item) => sum + item.rating, 0) / feedbackPage.items.length).toFixed(1)
          : "0.0",
    }),
    [feedbackPage],
  );

  const handleDelete = async (feedbackId) => {
    const confirmed = window.confirm("Delete this feedback entry?");
    if (!confirmed) {
      return;
    }

    setIsDeleting(feedbackId);
    setError("");
    try {
      await api.delete(`/feedback/${feedbackId}`);
      setFeedbackPage((current) => ({
        ...current,
        items: current.items.filter((item) => item.id !== feedbackId),
        totalElements: Math.max(current.totalElements - 1, 0),
      }));
    } catch (requestError) {
      setError(getApiErrorMessage(requestError, "Failed to delete feedback."));
    } finally {
      setIsDeleting(null);
    }
  };

  return (
    <div className="grid gap-4">
      <SectionCard
        title="Feedback management"
        kicker="Coach workspace"
      action={
        <div className="flex flex-wrap gap-3">
          <select
            className="field-input w-full sm:w-48"
              value={filters.climberId}
              onChange={(event) => {
                setPage(0);
                setFilters((current) => ({ ...current, climberId: event.target.value }));
              }}
            >
              <option value="">All climbers</option>
              {climbers.map((climber) => (
                <option key={climber.id} value={climber.id}>
                  {climber.name}
                </option>
              ))}
            </select>
            <select
              className="field-input w-full sm:w-40"
              value={filters.rating}
              onChange={(event) => {
                setPage(0);
                setFilters((current) => ({ ...current, rating: event.target.value }));
              }}
            >
              <option value="">All ratings</option>
              {[5, 4, 3, 2, 1].map((value) => (
                <option key={value} value={value}>
                  {value} stars
                </option>
              ))}
            </select>
            <select
              className="field-input w-full sm:w-48"
              value={sort}
              onChange={(event) => {
                setPage(0);
                setSort(event.target.value);
              }}
            >
              <option value="createdAt:desc">Newest feedback</option>
              <option value="createdAt:asc">Oldest feedback</option>
              <option value="rating:desc">Highest rating</option>
              <option value="rating:asc">Lowest rating</option>
            </select>
          </div>
        }
      >
        <div className="mb-5 grid gap-4 md:grid-cols-2">
          <div className="stat-tile">
            <p className="text-xs uppercase tracking-[0.25em] text-slate-500">Visible reviews</p>
            <p className="mt-4 text-3xl font-semibold text-white">{summary.total}</p>
          </div>
          <div className="stat-tile">
            <p className="text-xs uppercase tracking-[0.25em] text-slate-500">Page average</p>
            <p className="mt-4 text-3xl font-semibold text-white">{summary.average}</p>
          </div>
        </div>

        {isLoading ? <LoadingState label="Loading feedback" /> : null}
        {!isLoading && error ? <EmptyState title="Feedback unavailable" description={error} /> : null}
        {!isLoading && !error && !feedbackPage.items.length ? (
          <EmptyState title="No feedback found" description="Adjust the filters or create a new feedback entry." />
        ) : null}
        {!isLoading && !error && feedbackPage.items.length ? (
          <div className="space-y-3">
            {feedbackPage.items.map((item) => (
              <article key={item.id} className="rounded-2xl border border-white/10 bg-white/5 p-5">
                <div className="flex flex-wrap items-start justify-between gap-4">
                  <div>
                    <div className="flex flex-wrap items-center gap-3">
                      <h3 className="text-lg font-semibold text-white">{item.routeName}</h3>
                      <StatusPill label={`${item.rating}/5`} tone={item.rating >= 4 ? "success" : item.rating === 3 ? "info" : "warm"} />
                    </div>
                    <p className="mt-2 text-sm text-slate-400">
                      {item.climberName} · {item.difficulty} · {item.venue}
                    </p>
                    <p className="mt-1 text-xs uppercase tracking-[0.2em] text-slate-500">
                      {item.climbDate} · {item.climbStatus}
                    </p>
                  </div>
                  <div className="flex flex-wrap gap-3">
                    <Link className="secondary-button" to={`/coach/feedback/new?edit=${item.id}`}>
                      Edit
                    </Link>
                    <button
                      type="button"
                      className="rounded-2xl border border-rose-400/20 bg-rose-400/10 px-4 py-3 text-sm font-semibold text-rose-200 transition hover:bg-rose-400/20 disabled:cursor-not-allowed disabled:opacity-60"
                      disabled={isDeleting === item.id}
                      onClick={() => handleDelete(item.id)}
                    >
                      {isDeleting === item.id ? "Deleting..." : "Delete"}
                    </button>
                  </div>
                </div>
                <p className="mt-4 text-sm leading-7 text-slate-300">{item.comment}</p>
              </article>
            ))}
            <PaginationControls
              page={feedbackPage.page}
              totalPages={feedbackPage.totalPages}
              hasNext={feedbackPage.hasNext}
              hasPrevious={feedbackPage.hasPrevious}
              onPageChange={setPage}
            />
          </div>
        ) : null}
      </SectionCard>
    </div>
  );
}
