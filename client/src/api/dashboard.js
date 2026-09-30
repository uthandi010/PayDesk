import { apiRequest } from "./client";

export const getDashboardSummary = () => apiRequest("/api/dashboard/summary");
