import { Navigate, Route, Routes } from "react-router-dom";
import AuthenticatedLayout from "./components/layout/AuthenticatedLayout";
import LoginPage from "./pages/auth/LoginPage";
import RegisterPage from "./pages/auth/RegisterPage";
import BadgesPage from "./pages/climber/BadgesPage";
import ClimbLogsPage from "./pages/climber/ClimbLogsPage";
import ClimberDashboardPage from "./pages/climber/ClimberDashboardPage";
import MyFeedbackPage from "./pages/climber/MyFeedbackPage";
import NewClimbLogPage from "./pages/climber/NewClimbLogPage";
import ClimberDetailPage from "./pages/coach/ClimberDetailPage";
import ClimbersPage from "./pages/coach/ClimbersPage";
import CoachBadgeRulesPage from "./pages/coach/CoachBadgeRulesPage";
import CoachFeedbackPage from "./pages/coach/CoachFeedbackPage";
import CoachDashboardPage from "./pages/coach/CoachDashboardPage";
import NewFeedbackPage from "./pages/coach/NewFeedbackPage";
import ProtectedRoute from "./router/ProtectedRoute";
import { climberNavigation, coachNavigation } from "./utils/navigation";

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<Navigate to="/login" replace />} />
      <Route path="/login" element={<LoginPage />} />
      <Route path="/register" element={<RegisterPage />} />

      <Route
        path="/climber"
        element={
          <ProtectedRoute allowedRoles={["CLIMBER"]}>
            <AuthenticatedLayout areaLabel="Climber Workspace" navigation={climberNavigation} />
          </ProtectedRoute>
        }
      >
        <Route path="dashboard" element={<ClimberDashboardPage />} />
        <Route path="climbs" element={<ClimbLogsPage />} />
        <Route path="climbs/new" element={<NewClimbLogPage />} />
        <Route path="badges" element={<BadgesPage />} />
        <Route path="feedback" element={<MyFeedbackPage />} />
      </Route>

      <Route
        path="/coach"
        element={
          <ProtectedRoute allowedRoles={["COACH"]}>
            <AuthenticatedLayout areaLabel="Coach Workspace" navigation={coachNavigation} />
          </ProtectedRoute>
        }
      >
        <Route path="dashboard" element={<CoachDashboardPage />} />
        <Route path="climbers" element={<ClimbersPage />} />
        <Route path="climbers/:id" element={<ClimberDetailPage />} />
        <Route path="badges" element={<CoachBadgeRulesPage />} />
        <Route path="feedback" element={<CoachFeedbackPage />} />
        <Route path="feedback/new" element={<NewFeedbackPage />} />
      </Route>

      <Route path="*" element={<Navigate to="/login" replace />} />
    </Routes>
  );
}
