import { useState } from "react";
import { Link, Navigate, useNavigate } from "react-router-dom";
import brandMark from "../../assets/brand-mark.svg";
import { useAuth } from "../../hooks/useAuth";
import { getApiErrorMessage } from "../../utils/api";
import { getHomePathForRole } from "../../utils/auth";

export default function LoginPage() {
  const navigate = useNavigate();
  const { login, isAuthenticated, user, isLoading } = useAuth();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
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
      const signedInUser = await login({ email, password });
      navigate(getHomePathForRole(signedInUser.role));
    } catch (requestError) {
      setError(getApiErrorMessage(requestError, "Login failed."));
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="app-shell min-h-screen px-4 py-6 sm:px-6 lg:px-8">
      <div className="mx-auto grid min-h-[calc(100vh-3rem)] max-w-6xl gap-6 lg:grid-cols-[1.1fr_0.9fr]">
        <section className="glass-panel relative overflow-hidden p-8 sm:p-10">
          <div className="absolute inset-0 bg-[radial-gradient(circle_at_top_left,rgba(255,122,24,0.16),transparent_28%),radial-gradient(circle_at_bottom_right,rgba(138,215,255,0.14),transparent_32%)]" />
          <div className="relative flex h-full flex-col justify-between gap-10">
            <div>
              <span className="eyebrow">BETAUP MOBILE</span>
              <h1 className="max-w-xl font-display text-6xl uppercase leading-none tracking-[0.05em] text-white sm:text-7xl">
                Welcome back to BetaUp
              </h1>
              <p className="mt-6 max-w-xl text-base text-slate-300 sm:text-lg">
                Sign in to track climbs, monitor progress, and access role-based tools for climbers and coaches.
              </p>
            </div>

            <div className="grid gap-4 sm:grid-cols-3">
              {[
                ["Secure auth", "JWT login, register, and protected API calls"],
                ["Role-based access", "Climber and coach workspaces with tailored tools"],
                ["Synced backend", "Live data connected to the Spring Boot API"],
              ].map(([title, text]) => (
                <div key={title} className="rounded-3xl border border-white/10 bg-black/20 p-5">
                  <p className="text-xs uppercase tracking-[0.25em] text-ice">{title}</p>
                  <p className="mt-3 text-sm text-slate-300">{text}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        <section className="glass-panel flex items-center justify-center p-8 sm:p-10">
          <div className="w-full max-w-md">
            <div className="mb-8 flex items-center gap-4">
              <img src={brandMark} alt="BetaUp brand mark" className="h-14 w-14 rounded-2xl border border-white/10 bg-black/20 p-2" />
              <div>
                <p className="font-display text-4xl uppercase tracking-[0.12em] text-ember">BetaUp</p>
                <p className="text-sm text-slate-400">Sign in to your connected workspace</p>
              </div>
            </div>

            <form className="space-y-5" onSubmit={handleSubmit}>
              <div>
                <label className="mb-2 block text-sm font-medium text-slate-200" htmlFor="email">
                  Email
                </label>
                <input
                  id="email"
                  className="field-input"
                  type="email"
                  placeholder="coach@betaup.local"
                  value={email}
                  onChange={(event) => setEmail(event.target.value)}
                />
              </div>

              <div>
                <label className="mb-2 block text-sm font-medium text-slate-200" htmlFor="password">
                  Password
                </label>
                <input
                  id="password"
                  className="field-input"
                  type="password"
                  placeholder="Enter your password"
                  value={password}
                  onChange={(event) => setPassword(event.target.value)}
                />
              </div>

              {error ? <div className="rounded-2xl border border-rose-400/20 bg-rose-400/10 px-4 py-3 text-sm text-rose-200">{error}</div> : null}

              <button type="submit" className="primary-button w-full disabled:cursor-not-allowed disabled:opacity-60" disabled={isSubmitting}>
                {isSubmitting ? "Signing In..." : "Sign In"}
              </button>
            </form>

            <div className="mt-6 flex items-center justify-between text-sm text-slate-400">
              <span>Need a real account?</span>
              <Link className="text-ice transition hover:text-white" to="/register">
                Create one
              </Link>
            </div>
          </div>
        </section>
      </div>
    </div>
  );
}
