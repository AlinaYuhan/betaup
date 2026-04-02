import { useEffect, useState } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import api from "../../api/axios";
import EmptyState from "../../components/common/EmptyState";
import LoadingState from "../../components/common/LoadingState";
import SectionCard from "../../components/common/SectionCard";
import { getApiErrorMessage } from "../../utils/api";

const initialForm = {
  routeName: "",
  difficulty: "",
  date: "",
  venue: "",
  status: "COMPLETED",
  notes: "",
};

export default function NewClimbLogPage() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const editingId = searchParams.get("edit");
  const [formData, setFormData] = useState(initialForm);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");
  const [loadError, setLoadError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isLoading, setIsLoading] = useState(Boolean(editingId));

  useEffect(() => {
    async function loadClimbLog() {
      if (!editingId) {
        setFormData(initialForm);
        setIsLoading(false);
        return;
      }

      try {
        const response = await api.get(`/climbs/${editingId}`);
        const climb = response.data.data;
        setFormData({
          routeName: climb.routeName,
          difficulty: climb.difficulty,
          date: climb.date,
          venue: climb.venue,
          status: climb.status,
          notes: climb.notes ?? "",
        });
      } catch (requestError) {
        setLoadError(getApiErrorMessage(requestError, "Failed to load climb log."));
      } finally {
        setIsLoading(false);
      }
    }

    loadClimbLog();
  }, [editingId]);

  const handleSubmit = async (event) => {
    event.preventDefault();
    setMessage("");
    setError("");
    setIsSubmitting(true);

    try {
      if (editingId) {
        await api.put(`/climbs/${editingId}`, formData);
        setMessage("Climb log updated successfully.");
      } else {
        await api.post("/climbs", formData);
        setMessage("Climb log created successfully.");
      }

      navigate("/climber/climbs");
    } catch (requestError) {
      setError(getApiErrorMessage(requestError, editingId ? "Failed to update climb log." : "Failed to create climb log."));
    } finally {
      setIsSubmitting(false);
    }
  };

  if (isLoading) {
    return <LoadingState label="Loading climb log" />;
  }

  if (loadError) {
    return <EmptyState title="Climb log unavailable" description={loadError} />;
  }

  return (
    <SectionCard title={editingId ? "Edit climb entry" : "New climb entry"} kicker={editingId ? "Update form" : "Live form"}>
      <form className="grid gap-4 md:grid-cols-2" onSubmit={handleSubmit}>
        <input
          className="field-input"
          placeholder="Route name"
          value={formData.routeName}
          onChange={(event) => setFormData((current) => ({ ...current, routeName: event.target.value }))}
        />
        <input
          className="field-input"
          placeholder="Difficulty"
          value={formData.difficulty}
          onChange={(event) => setFormData((current) => ({ ...current, difficulty: event.target.value }))}
        />
        <input
          className="field-input"
          type="date"
          value={formData.date}
          onChange={(event) => setFormData((current) => ({ ...current, date: event.target.value }))}
        />
        <input
          className="field-input"
          placeholder="Venue"
          value={formData.venue}
          onChange={(event) => setFormData((current) => ({ ...current, venue: event.target.value }))}
        />
        <select
          className="field-input"
          value={formData.status}
          onChange={(event) => setFormData((current) => ({ ...current, status: event.target.value }))}
        >
          <option value="COMPLETED">Completed</option>
          <option value="ATTEMPTED">Attempted</option>
        </select>
        <div className="rounded-2xl border border-dashed border-white/15 bg-white/5 p-4 text-sm text-slate-400">
          {editingId
            ? "Updating a climb log can unlock newly eligible badges if you change an attempt into a completion."
            : "This form writes directly to the backend and updates badge progress after save."}
        </div>
        <textarea
          className="field-input md:col-span-2"
          rows="5"
          placeholder="Session notes"
          value={formData.notes}
          onChange={(event) => setFormData((current) => ({ ...current, notes: event.target.value }))}
        />
        {error && !editingId ? <div className="rounded-2xl border border-rose-400/20 bg-rose-400/10 px-4 py-3 text-sm text-rose-200 md:col-span-2">{error}</div> : null}
        {message ? <div className="rounded-2xl border border-emerald-400/20 bg-emerald-400/10 px-4 py-3 text-sm text-emerald-200 md:col-span-2">{message}</div> : null}
        <button type="submit" className="primary-button md:col-span-2 md:w-fit disabled:cursor-not-allowed disabled:opacity-60" disabled={isSubmitting}>
          {isSubmitting ? "Saving..." : editingId ? "Update Climb Log" : "Save Climb Log"}
        </button>
      </form>
    </SectionCard>
  );
}
