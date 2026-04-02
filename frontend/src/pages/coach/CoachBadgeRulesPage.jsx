import { useEffect, useMemo, useState } from "react";
import api from "../../api/axios";
import EmptyState from "../../components/common/EmptyState";
import LoadingState from "../../components/common/LoadingState";
import SectionCard from "../../components/common/SectionCard";
import StatusPill from "../../components/common/StatusPill";
import { getApiErrorMessage } from "../../utils/api";

const initialForm = {
  badgeKey: "",
  name: "",
  description: "",
  threshold: 1,
  criteriaType: "TOTAL_LOGS",
};

const criteriaOptions = [
  { value: "TOTAL_LOGS", label: "Total logs" },
  { value: "COMPLETED_CLIMBS", label: "Completed climbs" },
  { value: "FEEDBACK_RECEIVED", label: "Feedback received" },
];

export default function CoachBadgeRulesPage() {
  const [rules, setRules] = useState([]);
  const [formData, setFormData] = useState(initialForm);
  const [editingRuleId, setEditingRuleId] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [deletingId, setDeletingId] = useState(null);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

  const isEditing = Boolean(editingRuleId);

  async function loadRules() {
    setIsLoading(true);
    setError("");
    try {
      const response = await api.get("/badges/rules");
      setRules(response.data.data);
    } catch (requestError) {
      setError(getApiErrorMessage(requestError, "Failed to load badge rules."));
    } finally {
      setIsLoading(false);
    }
  }

  useEffect(() => {
    loadRules();
  }, []);

  const summary = useMemo(
    () => ({
      total: rules.length,
      highestThreshold: rules.length ? Math.max(...rules.map((rule) => rule.threshold)) : 0,
    }),
    [rules],
  );

  const resetForm = () => {
    setEditingRuleId(null);
    setFormData(initialForm);
  };

  const handleEdit = (rule) => {
    setEditingRuleId(rule.id);
    setMessage("");
    setError("");
    setFormData({
      badgeKey: rule.badgeKey,
      name: rule.name,
      description: rule.description,
      threshold: rule.threshold,
      criteriaType: rule.criteriaType,
    });
  };

  const handleSubmit = async (event) => {
    event.preventDefault();
    setIsSubmitting(true);
    setError("");
    setMessage("");

    try {
      if (isEditing) {
        await api.put(`/badges/rules/${editingRuleId}`, {
          name: formData.name.trim(),
          description: formData.description.trim(),
          threshold: Number(formData.threshold),
          criteriaType: formData.criteriaType,
        });
        setMessage("Badge rule updated.");
      } else {
        await api.post("/badges/rules", {
          badgeKey: formData.badgeKey.trim(),
          name: formData.name.trim(),
          description: formData.description.trim(),
          threshold: Number(formData.threshold),
          criteriaType: formData.criteriaType,
        });
        setMessage("Badge rule created.");
      }

      resetForm();
      await loadRules();
    } catch (requestError) {
      setError(getApiErrorMessage(requestError, isEditing ? "Failed to update badge rule." : "Failed to create badge rule."));
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDelete = async (ruleId) => {
    const confirmed = window.confirm("Delete this badge rule? Earned copies of this badge will be removed as well.");
    if (!confirmed) {
      return;
    }

    setDeletingId(ruleId);
    setError("");
    setMessage("");
    try {
      await api.delete(`/badges/rules/${ruleId}`);
      if (editingRuleId === ruleId) {
        resetForm();
      }
      setMessage("Badge rule deleted.");
      await loadRules();
    } catch (requestError) {
      setError(getApiErrorMessage(requestError, "Failed to delete badge rule."));
    } finally {
      setDeletingId(null);
    }
  };

  return (
    <div className="grid gap-4 xl:grid-cols-[1.2fr_0.8fr]">
      <SectionCard title="Badge rule catalog" kicker="Coach controls">
        <div className="mb-5 grid gap-4 md:grid-cols-2">
          <div className="stat-tile">
            <p className="text-xs uppercase tracking-[0.25em] text-slate-500">Configured rules</p>
            <p className="mt-4 text-3xl font-semibold text-white">{summary.total}</p>
          </div>
          <div className="stat-tile">
            <p className="text-xs uppercase tracking-[0.25em] text-slate-500">Highest threshold</p>
            <p className="mt-4 text-3xl font-semibold text-white">{summary.highestThreshold}</p>
          </div>
        </div>

        {isLoading ? <LoadingState label="Loading badge rules" /> : null}
        {!isLoading && error && !rules.length ? <EmptyState title="Rules unavailable" description={error} /> : null}
        {!isLoading && !error && !rules.length ? (
          <EmptyState title="No badge rules yet" description="Create the first rule to define how climbers unlock milestones." />
        ) : null}
        {!isLoading && rules.length ? (
          <div className="space-y-3">
            {rules.map((rule) => (
              <article key={rule.id} className="rounded-2xl border border-white/10 bg-white/5 p-5">
                <div className="flex flex-wrap items-start justify-between gap-4">
                  <div>
                    <div className="flex flex-wrap items-center gap-3">
                      <h3 className="text-lg font-semibold text-white">{rule.name}</h3>
                      <StatusPill label={rule.badgeKey} tone="info" />
                    </div>
                    <p className="mt-2 text-sm leading-7 text-slate-300">{rule.description}</p>
                    <p className="mt-3 text-xs uppercase tracking-[0.2em] text-slate-500">
                      {rule.criteriaType} · threshold {rule.threshold}
                    </p>
                  </div>
                  <div className="flex flex-wrap gap-3">
                    <button type="button" className="secondary-button" onClick={() => handleEdit(rule)}>
                      Edit
                    </button>
                    <button
                      type="button"
                      className="rounded-2xl border border-rose-400/20 bg-rose-400/10 px-4 py-3 text-sm font-semibold text-rose-200 transition hover:bg-rose-400/20 disabled:cursor-not-allowed disabled:opacity-60"
                      disabled={deletingId === rule.id}
                      onClick={() => handleDelete(rule.id)}
                    >
                      {deletingId === rule.id ? "Deleting..." : "Delete"}
                    </button>
                  </div>
                </div>
              </article>
            ))}
          </div>
        ) : null}
      </SectionCard>

      <SectionCard title={isEditing ? "Edit rule" : "Create rule"} kicker="Badge form">
        <form className="grid gap-4" onSubmit={handleSubmit}>
          <input
            className="field-input"
            placeholder="Badge key"
            value={formData.badgeKey}
            disabled={isEditing}
            onChange={(event) => setFormData((current) => ({ ...current, badgeKey: event.target.value }))}
          />
          <input
            className="field-input"
            placeholder="Display name"
            value={formData.name}
            onChange={(event) => setFormData((current) => ({ ...current, name: event.target.value }))}
          />
          <textarea
            className="field-input"
            rows="5"
            placeholder="Rule description"
            value={formData.description}
            onChange={(event) => setFormData((current) => ({ ...current, description: event.target.value }))}
          />
          <input
            className="field-input"
            type="number"
            min="1"
            value={formData.threshold}
            onChange={(event) => setFormData((current) => ({ ...current, threshold: event.target.value }))}
          />
          <select
            className="field-input"
            value={formData.criteriaType}
            onChange={(event) => setFormData((current) => ({ ...current, criteriaType: event.target.value }))}
          >
            {criteriaOptions.map((option) => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>

          <div className="rounded-2xl border border-dashed border-white/15 bg-white/5 p-4 text-sm leading-7 text-slate-400">
            Existing badge rules are no longer overwritten on every restart. Changes from this page persist until you edit them again.
          </div>

          {error ? <div className="rounded-2xl border border-rose-400/20 bg-rose-400/10 px-4 py-3 text-sm text-rose-200">{error}</div> : null}
          {message ? <div className="rounded-2xl border border-emerald-400/20 bg-emerald-400/10 px-4 py-3 text-sm text-emerald-200">{message}</div> : null}

          <div className="flex flex-wrap gap-3">
            <button type="submit" className="primary-button disabled:cursor-not-allowed disabled:opacity-60" disabled={isSubmitting}>
              {isSubmitting ? "Saving..." : isEditing ? "Update Rule" : "Create Rule"}
            </button>
            {isEditing ? (
              <button type="button" className="secondary-button" onClick={resetForm}>
                Cancel
              </button>
            ) : null}
          </div>
        </form>
      </SectionCard>
    </div>
  );
}
