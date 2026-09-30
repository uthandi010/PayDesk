import { apiRequest } from "./client";

export const listInvoices = () => apiRequest("/api/invoices");
export const getInvoice = (id) => apiRequest(`/api/invoices/${id}`);
export const retryInvoice = (id) => apiRequest(`/api/invoices/${id}/retry`, { method: "POST" });

export const getPublicInvoice = (token) => apiRequest(`/api/public/invoices/${token}`, { auth: false });
export const payPublicInvoice = (token) =>
  apiRequest(`/api/public/invoices/${token}/pay`, { method: "POST", auth: false });
