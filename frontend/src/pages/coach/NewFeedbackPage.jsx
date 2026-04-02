import { useEffect, useState } from "react";
import { useSearchParams } from "react-router-dom";
import api from "../../api/axios";
import EmptyState from "../../components/common/EmptyState";
import LoadingState from "../../components/common/LoadingState";
import SectionCard from "../../components/common/SectionCard";
import { getApiErrorMessage } from "../../utils/api";

export default function NewFeedbackPage() {
  const [searchParams] = useSearchParams();
  const defaultClimberId = searchParams.get("climberId") ?? "";
  const editingId = searchParams.get("edit") ?? "";
  const [climbers, setClimbers] = useState([]);
  const [availableClimbs, setAvailableClimbs] = useState([]);
  const [isBootLoading, setIsBootLoading] = useState(true);
  const [isEditingLoading, setIsEditingLoading] = useState(Boolean(editingId));
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [formData, setFormData] = useState({
    climberId: defaultClimberId,
    climbLogId: "",
    comment: "",
    rating: 5,
  });

  useEffect(() => {
    async function loadClimbers() {
      try {
        const response = await api.get("/coach/climbers/options");
        setClimbers(response.data.data);
      } catch (requestError) {
        setError(getApiErrorMessage(requestError, "Failed to load climbers."));
      } finally {
        setIsBootLoading(false);
      }
    }

    loadClimbers();
  }, []);

  useEffect(() => {
    async function loadFeedbackForEdit() {
      if (!editingId) {
        setIsEditingLoading(false);
        return;
      }

      try {
        const response = await api.get(`/feedback/${editingId}`);
        const feedback = response.data.data;
        setFormData({
          climberId: String(feedback.climberId),
          climbLogId: String(feedback.climbLogId),
          comment: feedback.comment,
          rating: feedback.rating,
        });
      } catch (requestError) {
        setError(getApiErrorMessage(requestError, "Failed to load feedback."));
      } finally {
        setIsEditingLoading(false);
      }
    }

    loadFeedbackForEdit();
  }, [editingId]);

  useEffect(() => {
    async function loadClimberDetail() {
      if (!formData.climberId) {
        setAvailableClimbs([]);
        return;
      }

      try {
        const response = await api.get(`/coach/climbers/${formData.climberId}`);
        setAvailableClimbs(response.data.data.recentClimbs ?? []);
      } catch (requestError) {
        setError(getApiErrorMessage(requestError, "Failed to load climb options."));
      }
    }

    loadClimberDetail();
  }, [formData.climberId]);

  const handleSubmit = async (event) => {
    event.preventDefault();
    setError("");
    setMessage("");
    setIsSubmitting(true);

    try {
      if (editingId) {
        await api.put(`/feedback/${editingId}`, {
          comment: formData.comment,
          rating: Number(formData.rating),
        });
        setMessage("Feedback updated successfully.");
      } else {
        await api.post("/feedback", {
          climberId: Number(formData.climberId),
          climbLogId: Number(formData.climbLogId),
          comment: formData.comment,
          rating: Number(formData.rating),
        });
        setMessage("Feedback submitted successfully.");
        setFormData((current) => ({
          ...current,
          climbLogId: "",
          comment: "",
          rating: 5,
        }));
      }
    } catch (requestError) {
      setError(getApiErrorMessage(requestError, editingId ? "Failed to update feedback." : "Failed to submit feedback."));
    } finally {
      setIsSubmitting(false);
    }
  };

  if (isBootLoading || isEditingLoading) {
    return <LoadingState label={editingId ? "Loading feedback editor" : "Loading feedback form"} />;
  }

  if (error && !climbers.length && !editingId) {
    return <EmptyState title="Form unavailable" description={error} />;
  }

  return (
    <SectionCard title={editingId ? "Edit feedback" : "New feedback draft"} kicker="Coach form">
      {!error && !climbers.length && !editingId ? (
        <EmptyState title="No climbers available" description="Create at least one climber account before submitting feedback." />
      ) : null}
      {(climbers.length || editingId) ? (
        <form className="grid gap-4 md:grid-cols-2" onSubmit={handleSubmit}>
          <select
            className="field-input"
            value={formData.climberId}
            disabled={Boolean(editingId)}
            onChange={(event) =>
              setFormData((current) => ({
                ...current,
                climberId: event.target.value,
                climbLogId: "",
              }))
            }
          >
            <option value="">Select climber</option>
            {climbers.map((climber) => (
              <option key={climber.id} value={climber.id}>
                {climber.name}
              </option>
            ))}
          </select>

          <select
            className="field-input"
            value={formData.climbLogId}
            disabled={Boolean(editingId)}
            onChange={(event) => setFormData((current) => ({ ...current, climbLogId: event.target.value }))}
          >
            <option value="">Select climb log</option>
            {availableClimbs.map((climb) => (
              <option key={climb.id} value={climb.id}>
                {climb.routeName} ({climb.difficulty})
              </option>
            ))}
          </select>

          <select
            className="field-input"
            value={formData.rating}
            onChange={(event) => setFormData((current) => ({ ...current, rating: event.target.value }))}
          >
            {[5, 4, 3, 2, 1].map((value) => (
              <option key={value} value={value}>
                Rating: {value}
              </option>
            ))}
          </select>

          <div className="rounded-2xl border border-dashed border-white/15 bg-white/5 p-4 text-sm text-slate-400">
            {editingId
              ? "Editing keeps the climber and climb association fixed, and only updates the review content."
              : "Feedback must be linked to a specific climber and one of their climb logs."}
          </div>

          <textarea
            className="field-input md:col-span-2"
            rows="6"
            placeholder="Coaching notes"
            value={formData.comment}
            onChange={(event) => setFormData((current) => ({ ...current, comment: event.target.value }))}
          />

          {error ? <div className="rounded-2xl border border-rose-400/20 bg-rose-400/10 px-4 py-3 text-sm text-rose-200 md:col-span-2">{error}</div> : null}
          {message ? <div className="rounded-2xl border border-emerald-400/20 bg-emerald-400/10 px-4 py-3 text-sm text-emerald-200 md:col-span-2">{message}</div> : null}

          <button type="submit" className="primary-button md:col-span-2 md:w-fit disabled:cursor-not-allowed disabled:opacity-60" disabled={isSubmitting}>
            {isSubmitting ? "Saving..." : editingId ? "Update Feedback" : "Submit Feedback"}
          </button>
        </form>
      ) : null}
    </SectionCard>
  );
}
