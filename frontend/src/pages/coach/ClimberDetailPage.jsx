import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import api from "../../api/axios";
import EmptyState from "../../components/common/EmptyState";
import LoadingState from "../../components/common/LoadingState";
import PaginationControls from "../../components/common/PaginationControls";
import SectionCard from "../../components/common/SectionCard";
import StatusPill from "../../components/common/StatusPill";
import { getApiErrorMessage } from "../../utils/api";
import { buildCollectionParams, parseSortValue } from "../../utils/collections";

export default function ClimberDetailPage() {
  const { id } = useParams();
  const [detail, setDetail] = useState(null);
  const [feedbackPage, setFeedbackPage] = useState({
    items: [],
    totalElements: 0,
    totalPages: 0,
    page: 0,
    hasNext: false,
    hasPrevious: false,
  });
  const [ratingFilter, setRatingFilter] = useState("");
  const [page, setPage] = useState(0);
  const [sort, setSort] = useState("createdAt:desc");
  const [error, setError] = useState("");
  const [feedbackError, setFeedbackError] = useState("");
  const [isLoading, setIsLoading] = useState(true);
  const [isFeedbackLoading, setIsFeedbackLoading] = useState(true);

  useEffect(() => {
    async function loadClimber() {
      try {
        const response = await api.get(`/coach/climbers/${id}`);
        setDetail(response.data.data);
      } catch (requestError) {
        setError(getApiErrorMessage(requestError, "Failed to load climber detail."));
      } finally {
        setIsLoading(false);
      }
    }

    loadClimber();
  }, [id]);

  useEffect(() => {
    async function loadFeedback() {
      setIsFeedbackLoading(true);
      setFeedbackError("");
      try {
        const { sortBy, sortDir } = parseSortValue(sort, "createdAt:desc");
        const params = buildCollectionParams({
          climberId: id,
          page,
          size: 4,
          rating: ratingFilter,
          sortBy,
          sortDir,
        });

        const response = await api.get(`/feedback?${params.toString()}`);
        setFeedbackPage(response.data.data);
      } catch (requestError) {
        setFeedbackError(getApiErrorMessage(requestError, "Failed to load filtered feedback."));
      } finally {
        setIsFeedbackLoading(false);
      }
    }

    loadFeedback();
  }, [id, page, ratingFilter, sort]);

  if (isLoading) {
    return <LoadingState label="Loading climber detail" />;
  }

  if (error && !detail) {
    return <EmptyState title="Climber detail unavailable" description={error} />;
  }

  return (
    <div className="grid gap-4">
      <SectionCard
        title={detail?.name || `Climber #${id}`}
        kicker="Detail shell"
        action={
          <Link className="secondary-button" to={`/coach/feedback/new?climberId=${id}`}>
            Draft Feedback
          </Link>
        }
      >
        <div className="mb-6 rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-slate-300">{detail?.email}</div>
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
          <div className="stat-tile">
            <StatusPill label="Total logs" tone="info" />
            <p className="mt-4 text-3xl font-semibold text-white">{detail?.climbCount}</p>
          </div>
          <div className="stat-tile">
            <StatusPill label="Completed" tone="success" />
            <p className="mt-4 text-3xl font-semibold text-white">{detail?.completedCount}</p>
          </div>
          <div className="stat-tile">
            <StatusPill label="Attempted" tone="warm" />
            <p className="mt-4 text-3xl font-semibold text-white">{detail?.attemptedCount}</p>
          </div>
          <div className="stat-tile">
            <StatusPill label="Feedback count" tone="info" />
            <p className="mt-4 text-3xl font-semibold text-white">{detail?.feedbackCount}</p>
          </div>
        </div>
      </SectionCard>

      <div className="grid gap-4 xl:grid-cols-2">
        <SectionCard title="Recent climbs" kicker="Live data">
          {!detail?.recentClimbs?.length ? (
            <EmptyState title="No climbs yet" description="This climber has not logged any sessions yet." />
          ) : (
            <div className="space-y-3">
              {detail.recentClimbs.map((climb) => (
                <article key={climb.id} className="rounded-2xl border border-white/10 bg-white/5 p-4">
                  <div className="flex flex-wrap items-center justify-between gap-3">
                    <div>
                      <h3 className="text-base font-semibold text-white">{climb.routeName}</h3>
                      <p className="mt-1 text-sm text-slate-400">
                        {climb.difficulty} at {climb.venue}
                      </p>
                    </div>
                    <StatusPill label={climb.status} tone={climb.status === "COMPLETED" ? "success" : "warm"} />
                  </div>
                </article>
              ))}
            </div>
          )}
        </SectionCard>

        <SectionCard
          title="Feedback history"
          kicker="Filtered reviews"
          action={
            <div className="flex flex-wrap gap-3">
              <select
                className="field-input w-full sm:w-48"
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
                <option value="createdAt:desc">Newest feedback</option>
                <option value="createdAt:asc">Oldest feedback</option>
                <option value="rating:desc">Highest rating</option>
                <option value="rating:asc">Lowest rating</option>
              </select>
            </div>
          }
        >
          {isFeedbackLoading ? <LoadingState label="Loading feedback" /> : null}
          {!isFeedbackLoading && feedbackError ? (
            <div className="rounded-2xl border border-rose-400/20 bg-rose-400/10 px-4 py-3 text-sm text-rose-200">{feedbackError}</div>
          ) : null}
          {!isFeedbackLoading && !feedbackPage.items.length ? (
            <EmptyState
              title={ratingFilter ? "No feedback for this rating" : "No feedback yet"}
              description={ratingFilter ? "Try broadening the filter or write a new review." : "Submit the first feedback note from the coach workspace."}
            />
          ) : null}
          {!isFeedbackLoading && feedbackPage.items.length ? (
            <div className="space-y-3">
              {feedbackPage.items.map((feedback) => (
                <article key={feedback.id} className="rounded-2xl border border-white/10 bg-white/5 p-4">
                  <div className="flex flex-wrap items-center justify-between gap-3">
                    <div>
                      <h3 className="text-base font-semibold text-white">{feedback.routeName}</h3>
                      <p className="mt-1 text-sm text-slate-400">
                        {feedback.difficulty} · {feedback.venue}
                      </p>
                    </div>
                    <StatusPill label={`${feedback.rating}/5`} />
                  </div>
                  <p className="mt-3 text-sm leading-7 text-slate-300">{feedback.comment}</p>
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
    </div>
  );
}
