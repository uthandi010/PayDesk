const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? "http://localhost:3000";
const TOKEN_KEY = "paydesk_token";

export class ApiError extends Error {
  constructor(status, message) {
    super(message);
    this.name = "ApiError";
    this.status = status;
  }
}

function extractErrorMessage(data, status) {
  if (data && typeof data.message === "string") return data.message;
  return `Request failed with status ${status}`;
}

export function getToken() {
  return localStorage.getItem(TOKEN_KEY);
}

export function setToken(token) {
  if (token) {
    localStorage.setItem(TOKEN_KEY, token);
  } else {
    localStorage.removeItem(TOKEN_KEY);
  }
}

export async function apiRequest(path, { method = "GET", body, auth = true } = {}) {
  const headers = {};
  const token = getToken();
  if (auth && token) {
    headers.Authorization = `Bearer ${token}`;
  }
  if (body !== undefined) {
    headers["Content-Type"] = "application/json";
  }

  const response = await fetch(`${API_BASE_URL}${path}`, {
    method,
    headers,
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });

  if (response.status === 204) {
    return undefined;
  }

  const contentType = response.headers.get("content-type") ?? "";
  const isJson = contentType.includes("application/json");
  const data = isJson ? await response.json() : undefined;

  if (!response.ok) {
    throw new ApiError(response.status, extractErrorMessage(data, response.status));
  }

  return data;
}

export async function downloadInvoicePdf(invoiceId) {
  const token = getToken();
  const response = await fetch(`${API_BASE_URL}/api/invoices/${invoiceId}/pdf`, {
    headers: token ? { Authorization: `Bearer ${token}` } : {},
  });

  if (!response.ok) {
    throw new ApiError(response.status, "Could not download the invoice PDF.");
  }

  const blob = await response.blob();
  const url = window.URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = `invoice-${invoiceId}.pdf`;
  document.body.appendChild(link);
  link.click();
  link.remove();
  window.URL.revokeObjectURL(url);
}
