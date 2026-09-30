import { apiRequest } from "./client";

export function register(name, email, password) {
  return apiRequest("/api/auth/register", {
    method: "POST",
    body: { name, email, password },
    auth: false,
  });
}

export function login(email, password) {
  return apiRequest("/api/auth/login", {
    method: "POST",
    body: { email, password },
    auth: false,
  });
}
