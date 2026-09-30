import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { apiRequest, ApiError, getToken, setToken } from "../client";

describe("apiRequest", () => {
  beforeEach(() => {
    localStorage.clear();
    vi.stubGlobal("fetch", vi.fn());
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it("does not send an Authorization header when there is no token", async () => {
    setToken(null);
    fetch.mockResolvedValue(new Response(JSON.stringify({ ok: true }), { status: 200, headers: { "content-type": "application/json" } }));

    await apiRequest("/api/anything");

    const [, init] = fetch.mock.calls[0];
    expect(init.headers.Authorization).toBeUndefined();
  });

  it("attaches a Bearer Authorization header when a token is stored", async () => {
    setToken("test-token-123");
    fetch.mockResolvedValue(new Response(JSON.stringify({ ok: true }), { status: 200, headers: { "content-type": "application/json" } }));

    await apiRequest("/api/anything");

    const [, init] = fetch.mock.calls[0];
    expect(init.headers.Authorization).toBe("Bearer test-token-123");
  });

  it("does not attach a token when auth: false is requested", async () => {
    setToken("test-token-123");
    fetch.mockResolvedValue(new Response(JSON.stringify({ ok: true }), { status: 200, headers: { "content-type": "application/json" } }));

    await apiRequest("/api/public/invoices/abc", { auth: false });

    const [, init] = fetch.mock.calls[0];
    expect(init.headers.Authorization).toBeUndefined();
  });

  it("returns the parsed JSON body on success", async () => {
    fetch.mockResolvedValue(
      new Response(JSON.stringify({ id: 1, name: "Alex" }), { status: 200, headers: { "content-type": "application/json" } })
    );

    const result = await apiRequest("/api/customers/1");

    expect(result).toEqual({ id: 1, name: "Alex" });
  });

  it("returns undefined for a 204 No Content response", async () => {
    fetch.mockResolvedValue(new Response(null, { status: 204 }));

    const result = await apiRequest("/api/customers/1", { method: "DELETE" });

    expect(result).toBeUndefined();
  });

  it("extracts the server's message field on an error response", async () => {
    fetch.mockResolvedValue(
      new Response(JSON.stringify({ message: "Invalid email or password." }), {
        status: 401,
        headers: { "content-type": "application/json" },
      })
    );

    await expect(apiRequest("/api/auth/login", { method: "POST" })).rejects.toMatchObject({
      message: "Invalid email or password.",
      status: 401,
    });
  });

  it("falls back to a generic message when the server sends nothing usable", async () => {
    fetch.mockResolvedValue(new Response("", { status: 500 }));

    await expect(apiRequest("/api/anything")).rejects.toBeInstanceOf(ApiError);
  });

  it("round-trips the token through localStorage", () => {
    setToken("abc123");
    expect(getToken()).toBe("abc123");
    setToken(null);
    expect(getToken()).toBeNull();
  });
});
