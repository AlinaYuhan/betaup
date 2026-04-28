import axios from "axios";

const PRODUCTION_API_BASE_URL = "https://backend-production-7727.up.railway.app/api";

function resolveApiBaseUrl() {
  if (import.meta.env.VITE_API_BASE_URL) {
    return import.meta.env.VITE_API_BASE_URL;
  }

  if (typeof window !== "undefined") {
    const { hostname } = window.location;
    if (hostname === "localhost" || hostname === "127.0.0.1") {
      return "http://localhost:8080/api";
    }
  }

  return PRODUCTION_API_BASE_URL;
}

const api = axios.create({
  baseURL: resolveApiBaseUrl(),
  timeout: 10000,
});

api.interceptors.request.use((config) => {
  const rawAuth = window.localStorage.getItem("betaup.auth");

  if (rawAuth) {
    try {
      const parsedAuth = JSON.parse(rawAuth);

      if (parsedAuth?.token) {
        config.headers.Authorization = `Bearer ${parsedAuth.token}`;
      }
    } catch {
      window.localStorage.removeItem("betaup.auth");
    }
  }

  return config;
});

export default api;
