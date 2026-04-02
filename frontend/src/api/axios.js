import axios from "axios";

const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL ?? "http://localhost:8080/api",
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
