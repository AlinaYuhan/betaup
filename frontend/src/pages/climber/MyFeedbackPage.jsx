import { useEffect, useState } from "react";
import api from "../../api/axios";
import EmptyState from "../../components/common/EmptyState";
import LoadingState from "../../components/common/LoadingState";
import PaginationControls from "../../components/common/PaginationControls";
import SectionCard from "../../components/common/SectionCard";
import StatusPill from "../../components/common/StatusPill";
import { getApiErrorMessage } from "../../utils/api";
import { buildCollectionParams, parseSortValue } from "../../utils/collections";

export default function MyFeedbackPage() {
  const [feedbackPage, setFeedbackPage] = useState({
    items: [],
    totalElements: 0,
    totalPages: 0,
    page: 0,
    hasNext: false,
    hasPrevious: false,
  });
  const [ratingFilter, setRatingFilter] = useState("");
  const [error, setError] = useState("");
  const [isLoading, setIsLoading] = useState(true);
  const [page, setPage] = useState(0);
  const [sort, setSort] = useState("createdAt:desc");

  useEffect(() => {
    async function loadFeedback() {
      setIsLoading(true);
      setError("");

      try {
        const { sortBy, sortDir } = parseSortValue(sort, "createdAt:desc");
        const params = buildCollectionParams({
          page,
          size: 6,
          rating: ratingFilter,
          sortBy,
          sortDir,
        });
        const response = await api.get(`/feedback?${params.toString()}`);
        setFeedbackPage(response.data.data);
      } catch (requestError) {
        setError(getApiErrorMessage(requestError, "Failed to load feedback."));
      } finally {
        setIsLoading(false);
      }
    }

    loadFeedback();
  }, [page, ratingFilter, sort]);

  return (
    <SectionCard
      title="My feedback"
      kicker="Coach review stream"
      action={
        <div className="flex flex-wrap gap-3">
          <select
            className="field-input w-full sm:w-40"
            value={ratingFilter}
            onChange={(event) => {
              setPage(0);
              setRatingFilter(event.target.value);
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
            <option value="createdAt:desc">Newest notes</option>
            <option value="createdAt:asc">Oldest notes</option>
            <option value="rating:desc">Highest rating</option>
            <option value="rating:asc">Lowest rating</option>
          </select>
        </div>
      }
    >
      {isLoading ? <LoadingState label="Loading feedback" /> : null}
      {!isLoading && error ? <EmptyState title="Feedback unavailable" description={error} /> : null}
      {!isLoading && !error && !feedbackPage.items.length ? (
        <EmptyState title="No feedback yet" description="Coach reviews will appear here after a coach submits feedback for one of your climb logs." />
      ) : null}
      {!isLoading && !error && feedbackPage.items.length ? (
        <div className="space-y-4">
          {feedbackPage.items.map((item) => (
            <article key={item.id} className="rounded-2xl border border-white/10 bg-white/5 p-5">
              <div className="flex flex-wrap items-center justify-between gap-3">
                <div>
                  <h3 className="text-lg font-semibold text-white">{item.coachName}</h3>
                  <p className="mt-1 text-sm text-slate-400">
                    {item.routeName} · {item.difficulty} · {item.venue}
                  </p>
                  <p className="mt-2 text-xs uppercase tracking-[0.2em] text-slate-500">
                    {item.climbDate} · {item.climbStatus}
                  </p>
                </div>
                <StatusPill label={`${item.rating}/5`} />
              </div>
              <p className="mt-3 text-sm leading-7 text-slate-300">{item.comment}</p>
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
  );
}
