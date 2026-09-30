import { screen, waitFor, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { SubscriptionsPage } from "../SubscriptionsPage";
import { renderWithProviders as render } from "../../test/renderWithProviders";

vi.mock("../../api/subscriptions", () => ({
  listSubscriptions: vi.fn(),
  createSubscription: vi.fn(),
  cancelSubscription: vi.fn(),
  renewSubscription: vi.fn(),
}));
vi.mock("../../api/customers", () => ({ listCustomers: vi.fn() }));
vi.mock("../../api/plans", () => ({ listPlans: vi.fn() }));

import * as subscriptionsApi from "../../api/subscriptions";
import * as customersApi from "../../api/customers";
import * as plansApi from "../../api/plans";

const subscription = {
  id: 1,
  status: "active",
  currentPeriodStart: "2026-09-01T00:00:00.000Z",
  currentPeriodEnd: "2026-10-01T00:00:00.000Z",
  customer: { id: 1, name: "Alex Customer", email: "alex@example.com" },
  plan: { id: 1, name: "Pro", amountCents: 2900, interval: "month" },
  latestInvoiceId: 1,
};

function list() {
  return within(screen.getByRole("list"));
}

describe("SubscriptionsPage", () => {
  beforeEach(() => {
    vi.resetAllMocks();
    customersApi.listCustomers.mockResolvedValue([{ id: 1, name: "Alex Customer" }]);
    plansApi.listPlans.mockResolvedValue([{ id: 1, name: "Pro", amountCents: 2900, interval: "month" }]);
  });

  it("lists existing subscriptions with a status badge", async () => {
    subscriptionsApi.listSubscriptions.mockResolvedValue([subscription]);

    render(<SubscriptionsPage />);

    await waitFor(() => expect(screen.getByRole("list")).toBeInTheDocument());
    expect(list().getByText(/Alex Customer/)).toBeInTheDocument();
    expect(list().getByText("active")).toBeInTheDocument();
  });

  it("creates a subscription from the selected customer and plan", async () => {
    subscriptionsApi.listSubscriptions.mockResolvedValue([]);
    subscriptionsApi.createSubscription.mockResolvedValue(subscription);

    const user = userEvent.setup();
    render(<SubscriptionsPage />);
    await screen.findByText(/no subscriptions yet/i);

    await user.selectOptions(screen.getByLabelText(/customer/i), "1");
    await user.selectOptions(screen.getByLabelText(/^plan$/i), "1");
    await user.click(screen.getByRole("button", { name: /subscribe/i }));

    await waitFor(() => expect(subscriptionsApi.createSubscription).toHaveBeenCalledWith("1", "1"));
    await waitFor(() => expect(screen.getByRole("list")).toBeInTheDocument());
    expect(list().getByText(/Alex Customer/)).toBeInTheDocument();
  });

  it("cancels a subscription and hides its action buttons", async () => {
    subscriptionsApi.listSubscriptions.mockResolvedValue([subscription]);
    subscriptionsApi.cancelSubscription.mockResolvedValue({ ...subscription, status: "canceled" });

    const user = userEvent.setup();
    render(<SubscriptionsPage />);
    await waitFor(() => expect(screen.getByRole("list")).toBeInTheDocument());

    await user.click(list().getByRole("button", { name: /cancel/i }));

    await waitFor(() => expect(list().getByText("canceled")).toBeInTheDocument());
    expect(list().queryByRole("button", { name: /cancel/i })).not.toBeInTheDocument();
  });

  it("renews a subscription and reflects the updated period", async () => {
    subscriptionsApi.listSubscriptions.mockResolvedValue([subscription]);
    subscriptionsApi.renewSubscription.mockResolvedValue({
      ...subscription,
      currentPeriodEnd: "2026-11-01T00:00:00.000Z",
    });

    const user = userEvent.setup();
    render(<SubscriptionsPage />);
    await waitFor(() => expect(screen.getByRole("list")).toBeInTheDocument());

    await user.click(list().getByRole("button", { name: /renew/i }));

    await waitFor(() => expect(subscriptionsApi.renewSubscription).toHaveBeenCalledWith(1));
  });
});
