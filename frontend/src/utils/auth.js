export function getHomePathForRole(role) {
  return role === "COACH" ? "/coach/dashboard" : "/climber/explore";
}
