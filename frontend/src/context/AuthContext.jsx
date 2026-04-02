import { createContext, useEffect, useState } from "react";
import api from "../api/axios";
import { getApiErrorMessage } from "../utils/api";

export const AuthContext = createContext(null);

function readStoredAuth() {
  try {
    const rawAuth = window.localStorage.getItem("betaup.auth");
    return rawAuth ? JSON.parse(rawAuth) : { token: "", user: null };
  } catch {
    return { token: "", user: null };
  }
}

export function AuthProvider({ children }) {
  const storedAuth = readStoredAuth();
  const [token, setToken] = useState(storedAuth.token ?? "");
  const [user, setUser] = useState(storedAuth.user ?? null);
  const [isLoading, setIsLoading] = useState(Boolean(storedAuth.token));

  useEffect(() => {
    if (token && user) {
      window.localStorage.setItem("betaup.auth", JSON.stringify({ token, user }));
      return;
    }

    window.localStorage.removeItem("betaup.auth");
  }, [token, user]);

  useEffect(() => {
    async function bootstrapAuth() {
      if (!storedAuth.token) {
        setIsLoading(false);
        return;
      }

      try {
        const response = await api.get("/auth/me");
        setToken(storedAuth.token);
        setUser(response.data.data);
      } catch {
        setToken("");
        setUser(null);
        window.localStorage.removeItem("betaup.auth");
      } finally {
        setIsLoading(false);
      }
    }

    bootstrapAuth();
  }, []);

  const login = async ({ email, password }) => {
    const response = await api.post("/auth/login", { email, password });
    const auth = response.data.data;
    setToken(auth.token);
    setUser(auth.user);
    return auth.user;
  };

  const register = async ({ name, email, password, role }) => {
    const response = await api.post("/auth/register", { name, email, password, role });
    const auth = response.data.data;
    setToken(auth.token);
    setUser(auth.user);
    return auth.user;
  };

  const logout = () => {
    setToken("");
    setUser(null);
    window.localStorage.removeItem("betaup.auth");
  };

  return (
    <AuthContext.Provider
      value={{
        token,
        user,
        isAuthenticated: Boolean(token),
        isLoading,
        login,
        register,
        logout,
        getApiErrorMessage,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}
