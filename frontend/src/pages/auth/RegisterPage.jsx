import { useState } from "react";
import { Link, Navigate, useNavigate } from "react-router-dom";
import { useAuth } from "../../hooks/useAuth";
import { getApiErrorMessage } from "../../utils/api";
import { getHomePathForRole } from "../../utils/auth";

export default function RegisterPage() {
  const navigate = useNavigate();
  const { register, isAuthenticated, user, isLoading } = useAuth();
  const [formData, setFormData] = useState({
    name: "",
    email: "",
    password: "",
    role: "CLIMBER",
  });
  const [error, setError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  if (!isLoading && isAuthenticated && user) {
    return <Navigate to={getHomePathForRole(user.role)} replace />;
  }

  const handleSubmit = async (event) => {
    event.preventDefault();
    setError("");
    setIsSubmitting(true);

    try {
      const registeredUser = await register(formData);
      navigate(getHomePathForRole(registeredUser.role));
    } catch (requestError) {
      setError(getApiErrorMessage(requestError, "Registration failed."));
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="app-shell min-h-screen px-4 py-6 sm:px-6 lg:px-8">
      <div className="mx-auto grid min-h-[calc(100vh-3rem)] max-w-5xl items-center gap-6 lg:grid-cols-[0.95fr_1.05fr]">
        <section className="glass-panel p-8 sm:p-10">
          <span className="eyebrow">Round 4 Auth</span>
          <h1 className="font-display text-5xl uppercase tracking-[0.08em] text-white sm:text-6xl">Create a real BetaUp account.</h1>
          <div className="mt-8 space-y-4 text-sm leading-7 text-slate-300">
            <p>Registration now persists to MySQL through the Spring Boot backend.</p>
            <p>Passwords are hashed before storage, and successful registration returns a JWT-backed session.</p>
            <p>Select whether this account is a climber or a coach and the app will route you to the matching workspace.</p>
          </div>
        </section>

        <section className="glass-panel p-8 sm:p-10">
          <form className="space-y-5" onSubmit={handleSubmit}>
            <div>
              <label className="mb-2 block text-sm font-medium text-slate-200" htmlFor="name">
                Name
              </label>
              <input
                id="name"
                className="field-input"
                placeholder="Alex Summit"
                value={formData.name}
                onChange={(event) => setFormData((current) => ({ ...current, name: event.target.value }))}
              />
            </div>

            <div>
              <label className="mb-2 block text-sm font-medium text-slate-200" htmlFor="register-email">
                Email
              </label>
              <input
                id="register-email"
                className="field-input"
                type="email"
                placeholder="alex@betaup.local"
                value={formData.email}
                onChange={(event) => setFormData((current) => ({ ...current, email: event.target.value }))}
              />
            </div>

            <div>
              <label className="mb-2 block text-sm font-medium text-slate-200" htmlFor="register-password">
                Password
              </label>
              <input
                id="register-password"
                className="field-input"
                type="password"
                placeholder="At least 8 characters"
                value={formData.password}
                onChange={(event) => setFormData((current) => ({ ...current, password: event.target.value }))}
              />
            </div>

            <div>
              <label className="mb-2 block text-sm font-medium text-slate-200" htmlFor="role">
                Role
              </label>
              <select
                id="role"
                className="field-input"
                value={formData.role}
                onChange={(event) => setFormData((current) => ({ ...current, role: event.target.value }))}
              >
                <option value="CLIMBER">Climber</option>
                <option value="COACH">Coach</option>
              </select>
            </div>

            {error ? <div className="rounded-2xl border border-rose-400/20 bg-rose-400/10 px-4 py-3 text-sm text-rose-200">{error}</div> : null}

            <button type="submit" className="primary-button w-full disabled:cursor-not-allowed disabled:opacity-60" disabled={isSubmitting}>
              {isSubmitting ? "Creating Account..." : "Create Account"}
            </button>
          </form>

          <div className="mt-6 flex items-center justify-between text-sm text-slate-400">
            <span>Already registered?</span>
            <Link className="text-ice transition hover:text-white" to="/login">
              Back to sign in
            </Link>
          </div>
        </section>
      </div>
    </div>
  );
}
