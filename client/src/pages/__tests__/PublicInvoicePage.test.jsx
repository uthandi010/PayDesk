import { MemoryRouter, Route, Routes } from "react-router-dom";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { PublicInvoicePage } from "../PublicInvoicePage";
import { ApiError } from "../../api/client";

vi.mock("../../api/invoices", () => ({
  getPublicInvoice: vi.fn(),
  payPublicInvoice: vi.fn(),
}));

import * as invoicesApi from "../../api/invoices";

function renderAt(token) {
  return render(
    <MemoryRouter initialEntries={[`/invoice/${token}`]}>
      <Routes>
        <Route path="/invoice/:token" element={<PublicInvoicePage />} />
      </Routes>
    </MemoryRouter>
  );
}

const openInvoice = {
  id: 1,
  amountCents: 2900,
  status: "open",
  overdue: false,
  dueDate: "2026-10-01T00:00:00.000Z",
  paidAt: null,
  business: "Jamie Rivera",
  customer: { name: "Alex Customer", email: "alex@example.com" },
  plan: { name: "Pro" },
};

describe("PublicInvoicePage", () => {
  beforeEach(() => {
    vi.resetAllMocks();
  });

  it("shows an error when the token is invalid", async () => {
    invoicesApi.getPublicInvoice.mockRejectedValue(new ApiError(404, "Not found."));

    renderAt("bogus-token");

    expect(await screen.findByRole("alert")).toHaveTextContent("Not found.");
  });

  it("displays the invoice amount and a Pay now button when open", async () => {
    invoicesApi.getPublicInvoice.mockResolvedValue(openInvoice);

    renderAt("good-token");

    expect(await screen.findByText("$29.00")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /pay now/i })).toBeInTheDocument();
  });

  it("pays the invoice and shows the paid confirmation", async () => {
    invoicesApi.getPublicInvoice.mockResolvedValue(openInvoice);
    invoicesApi.payPublicInvoice.mockResolvedValue({
      ...openInvoice,
      status: "paid",
      paidAt: "2026-09-30T00:00:00.000Z",
    });

    const user = userEvent.setup();
    renderAt("good-token");

    await user.click(await screen.findByRole("button", { name: /pay now/i }));

    expect(await screen.findByText(/this invoice has been paid/i)).toBeInTheDocument();
    expect(invoicesApi.payPublicInvoice).toHaveBeenCalledWith("good-token");
  });
});
