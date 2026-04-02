import { Navigate } from "react-router-dom";
import LoadingState from "../components/common/LoadingState";
import { useAuth } from "../hooks/useAuth";
import { getHomePathForRole } from "../utils/auth";

export default function ProtectedRoute({ allowedRoles, children }) {
  const { token, user, isLoading } = useAuth();

  if (isLoading) {
    return <LoadingState label="Authorizing" />;
  }

  if (!token || !user) {
    return <Navigate to="/login" replace />;
  }

  if (allowedRoles?.length && !allowedRoles.includes(user.role)) {
    return <Navigate to={getHomePathForRole(user.role)} replace />;
  }

  return children;
}
