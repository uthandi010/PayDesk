import { apiRequest } from "./client";

export const listPlans = () => apiRequest("/api/plans");
export const createPlan = (data) => apiRequest("/api/plans", { method: "POST", body: data });
export const updatePlan = (id, data) => apiRequest(`/api/plans/${id}`, { method: "PATCH", body: data });
export const deletePlan = (id) => apiRequest(`/api/plans/${id}`, { method: "DELETE" });
