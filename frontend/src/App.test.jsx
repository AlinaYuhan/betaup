import React from "react";
import { render, screen } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { describe, expect, it, vi } from "vitest";
import App from "./App";
import { AuthContext } from "./context/auth-context";

function renderApp(initialEntries) {
  const authValue = {
    token: "",
    user: null,
    isAuthenticated: false,
    isLoading: false,
    login: vi.fn(),
    register: vi.fn(),
    logout: vi.fn(),
    getApiErrorMessage: vi.fn(),
  };

  return render(
    <AuthContext.Provider value={authValue}>
      <MemoryRouter initialEntries={initialEntries}>
        <App />
      </MemoryRouter>
    </AuthContext.Provider>,
  );
}

describe("App routes", () => {
  it("renders the login page for /login", async () => {
    renderApp(["/login"]);

    expect(await screen.findByRole("heading", { name: /welcome back to betaup/i })).toBeInTheDocument();
  });

  it("redirects / to /login", async () => {
    renderApp(["/"]);

    const matches = await screen.findAllByText(/sign in to your connected workspace/i);
    expect(matches.length).toBeGreaterThan(0);
  });
});
