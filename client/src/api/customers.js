import { apiRequest } from "./client";

export const listCustomers = () => apiRequest("/api/customers");
export const createCustomer = (data) => apiRequest("/api/customers", { method: "POST", body: data });
export const updateCustomer = (id, data) => apiRequest(`/api/customers/${id}`, { method: "PATCH", body: data });
export const deleteCustomer = (id) => apiRequest(`/api/customers/${id}`, { method: "DELETE" });
