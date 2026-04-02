import { useEffect, useMemo, useState } from "react";
import api from "../../api/axios";
import EmptyState from "../../components/common/EmptyState";
import LoadingState from "../../components/common/LoadingState";
import ProgressList from "../../components/common/ProgressList";
import SectionCard from "../../components/common/SectionCard";
import StatusPill from "../../components/common/StatusPill";
import { getApiErrorMessage } from "../../utils/api";

function criteriaLabel(criteriaType) {
  switch (criteriaType) {
    case "TOTAL_LOGS":
      return "Total logs";
    case "COMPLETED_CLIMBS":
      return "Completed climbs";
    case "FEEDBACK_RECEIVED":
      return "Feedback received";
    default:
      return "Progress";
  }
}

export default function BadgesPage() {
  const [progressItems, setProgressItems] = useState([]);
  const [error, setError] = useState("");
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    async function loadBadges() {
      try {
        const response = await api.get("/badges/progress");
        setProgressItems(response.data.data);
      } catch (requestError) {
        setError(getApiErrorMessage(requestError, "Failed to load badge data."));
      } finally {
        setIsLoading(false);
      }
    }

    loadBadges();
  }, []);

  const earned = useMemo(() => progressItems.filter((item) => item.earned), [progressItems]);
  const inProgress = useMemo(() => progressItems.filter((item) => !item.earned), [progressItems]);

  return (
    <div className="grid gap-4">
      <SectionCard title="Earned badges" kicker="Progress shelf">
        {isLoading ? <LoadingState label="Loading badges" /> : null}
        {!isLoading && error ? <EmptyState title="Badges unavailable" description={error} /> : null}
        {!isLoading && !error && !earned.length ? (
          <EmptyState title="No earned badges yet" description="Keep logging climbs and receiving coach feedback. Badges now unlock automatically when thresholds are met." />
        ) : null}
        {!isLoading && !error && earned.length ? (
          <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
            {earned.map((badge) => (
              <article key={badge.badgeId} className="rounded-3xl border border-white/10 bg-steel/80 p-5">
                <div className="flex flex-wrap items-center justify-between gap-3">
                  <StatusPill label={badge.name} tone="success" />
                  <span className="text-xs uppercase tracking-[0.18em] text-slate-500">{criteriaLabel(badge.criteriaType)}</span>
                </div>
                <p className="mt-5 text-sm leading-7 text-slate-300">{badge.description}</p>
                <p className="mt-4 text-xs uppercase tracking-[0.2em] text-slate-500">Awarded at {badge.awardedAt}</p>
              </article>
            ))}
          </div>
        ) : null}
      </SectionCard>

      <SectionCard title="Badge progress" kicker="Live thresholds">
        {!isLoading && !error && !inProgress.length ? (
          <EmptyState title="Everything unlocked" description="You have already reached every currently configured badge threshold." />
        ) : null}
        {!isLoading && !error && inProgress.length ? (
          <ProgressList
            items={inProgress.map((item) => ({
              label: item.name,
              value: Math.min(item.currentValue, item.threshold),
              maxValue: item.threshold,
              helper: `${criteriaLabel(item.criteriaType)}: ${item.currentValue}/${item.threshold}`,
            }))}
            formatter={(value) => `${value}`}
          />
        ) : null}
      </SectionCard>
    </div>
  );
}
