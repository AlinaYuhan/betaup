import React, { Suspense, lazy } from "react";
import { Navigate, Route, Routes } from "react-router-dom";
import LoadingState from "./components/common/LoadingState";
import AuthenticatedLayout from "./components/layout/AuthenticatedLayout";
import ProtectedRoute from "./router/ProtectedRoute";
import { climberNavigation, coachNavigation } from "./utils/navigation";

const LoginPage = lazy(() => import("./pages/auth/LoginPage"));
const RegisterPage = lazy(() => import("./pages/auth/RegisterPage"));
const BadgesPage = lazy(() => import("./pages/climber/BadgesPage"));
const ClimbLogsPage = lazy(() => import("./pages/climber/ClimbLogsPage"));
const ClimberDashboardPage = lazy(() => import("./pages/climber/ClimberDashboardPage"));
const GymExplorePage = lazy(() => import("./pages/climber/GymExplorePage"));
const MyFeedbackPage = lazy(() => import("./pages/climber/MyFeedbackPage"));
const NewClimbLogPage = lazy(() => import("./pages/climber/NewClimbLogPage"));
const ClimberDetailPage = lazy(() => import("./pages/coach/ClimberDetailPage"));
const ClimbersPage = lazy(() => import("./pages/coach/ClimbersPage"));
const CoachBadgeRulesPage = lazy(() => import("./pages/coach/CoachBadgeRulesPage"));
const CoachFeedbackPage = lazy(() => import("./pages/coach/CoachFeedbackPage"));
const CoachDashboardPage = lazy(() => import("./pages/coach/CoachDashboardPage"));
const NewFeedbackPage = lazy(() => import("./pages/coach/NewFeedbackPage"));

function RouteFallback() {
  return (
    <div className="app-shell min-h-screen px-4 py-6 sm:px-6 lg:px-8">
      <LoadingState label="Loading page" />
    </div>
  );
}

export default function App() {
  return (
    <Suspense fallback={<RouteFallback />}>
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
          <Route index element={<Navigate to="explore" replace />} />
          <Route path="explore" element={<GymExplorePage />} />
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
          <Route index element={<Navigate to="dashboard" replace />} />
          <Route path="dashboard" element={<CoachDashboardPage />} />
          <Route path="climbers" element={<ClimbersPage />} />
          <Route path="climbers/:id" element={<ClimberDetailPage />} />
          <Route path="badges" element={<CoachBadgeRulesPage />} />
          <Route path="feedback" element={<CoachFeedbackPage />} />
          <Route path="feedback/new" element={<NewFeedbackPage />} />
        </Route>

        <Route path="*" element={<Navigate to="/login" replace />} />
      </Routes>
    </Suspense>
  );
}
