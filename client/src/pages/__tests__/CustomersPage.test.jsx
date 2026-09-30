import { screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { CustomersPage } from "../CustomersPage";
import { ApiError } from "../../api/client";
import { renderWithProviders as render } from "../../test/renderWithProviders";

vi.mock("../../api/customers", () => ({
  listCustomers: vi.fn(),
  createCustomer: vi.fn(),
  deleteCustomer: vi.fn(),
}));

import * as customersApi from "../../api/customers";

describe("CustomersPage", () => {
  beforeEach(() => {
    vi.resetAllMocks();
  });

  it("shows an empty state when there are no customers", async () => {
    customersApi.listCustomers.mockResolvedValue([]);

    render(<CustomersPage />);

    expect(await screen.findByText(/no customers yet/i)).toBeInTheDocument();
  });

  it("lists customers returned by the API", async () => {
    customersApi.listCustomers.mockResolvedValue([
      { id: 1, name: "Alex Customer", email: "alex@example.com", activeSubscriptionCount: 2 },
    ]);

    render(<CustomersPage />);

    expect(await screen.findByText("Alex Customer")).toBeInTheDocument();
    expect(screen.getByText("alex@example.com")).toBeInTheDocument();
  });

  it("adds a new customer to the list on successful creation", async () => {
    customersApi.listCustomers.mockResolvedValue([]);
    customersApi.createCustomer.mockResolvedValue({
      id: 5,
      name: "Sam New",
      email: "sam@example.com",
      activeSubscriptionCount: 0,
    });

    const user = userEvent.setup();
    render(<CustomersPage />);
    await screen.findByText(/no customers yet/i);

    await user.type(screen.getByPlaceholderText("Alex Customer"), "Sam New");
    await user.type(screen.getByPlaceholderText("alex@example.com"), "sam@example.com");
    await user.click(screen.getByRole("button", { name: /add customer/i }));

    await waitFor(() =>
      expect(customersApi.createCustomer).toHaveBeenCalledWith({ name: "Sam New", email: "sam@example.com" })
    );
    expect(await screen.findByText("Sam New")).toBeInTheDocument();
  });

  it("shows the server's error message when creation fails", async () => {
    customersApi.listCustomers.mockResolvedValue([]);
    customersApi.createCustomer.mockRejectedValue(new ApiError(422, "Email is invalid"));

    const user = userEvent.setup();
    render(<CustomersPage />);
    await screen.findByText(/no customers yet/i);

    await user.type(screen.getByPlaceholderText("Alex Customer"), "Sam New");
    await user.type(screen.getByPlaceholderText("alex@example.com"), "not-an-email");
    await user.click(screen.getByRole("button", { name: /add customer/i }));

    expect(await screen.findByRole("alert")).toHaveTextContent("Email is invalid");
  });

  it("removes a customer from the list after deleting it", async () => {
    customersApi.listCustomers.mockResolvedValue([
      { id: 1, name: "Alex Customer", email: "alex@example.com", activeSubscriptionCount: 0 },
    ]);
    customersApi.deleteCustomer.mockResolvedValue(undefined);

    const user = userEvent.setup();
    render(<CustomersPage />);
    await screen.findByText("Alex Customer");

    await user.click(screen.getByRole("button", { name: /delete alex customer/i }));

    await waitFor(() => expect(screen.queryByText("Alex Customer")).not.toBeInTheDocument());
  });
});
