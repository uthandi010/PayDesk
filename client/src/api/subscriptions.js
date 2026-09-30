import { apiRequest } from "./client";

export const listSubscriptions = () => apiRequest("/api/subscriptions");
export const createSubscription = (customerId, planId) =>
  apiRequest("/api/subscriptions", { method: "POST", body: { customer_id: customerId, plan_id: planId } });
export const cancelSubscription = (id) => apiRequest(`/api/subscriptions/${id}/cancel`, { method: "PATCH" });
export const renewSubscription = (id) => apiRequest(`/api/subscriptions/${id}/renew`, { method: "POST" });
