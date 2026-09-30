import { useEffect, useState } from "react";
import { Plus, Trash2 } from "lucide-react";
import { NavBar } from "../components/NavBar";
import * as customersApi from "../api/customers";
import { ApiError } from "../api/client";

export function CustomersPage() {
  const [customers, setCustomers] = useState(null);
  const [error, setError] = useState(null);
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [creating, setCreating] = useState(false);

  useEffect(() => {
    customersApi
      .listCustomers()
      .then(setCustomers)
      .catch((err) => setError(err instanceof ApiError ? err.message : "Failed to load customers."));
  }, []);

  async function handleCreate(event) {
    event.preventDefault();
    if (!name.trim() || !email.trim()) return;

    setCreating(true);
    setError(null);
    try {
      const customer = await customersApi.createCustomer({ name: name.trim(), email: email.trim() });
      setCustomers((current) => [customer, ...current]);
      setName("");
      setEmail("");
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Could not create that customer.");
    } finally {
      setCreating(false);
    }
  }

  async function handleDelete(customer) {
    try {
      await customersApi.deleteCustomer(customer.id);
      setCustomers((current) => current.filter((c) => c.id !== customer.id));
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Could not delete that customer.");
    }
  }

  return (
    <>
      <NavBar />
      <div className="page-content">
        <div className="page-header">
          <div>
            <h1>Customers</h1>
            <p>The people and businesses you bill.</p>
          </div>
        </div>

        {error && (
          <div className="form-error" role="alert">
            {error}
          </div>
        )}

        <form className="inline-form" noValidate onSubmit={handleCreate}>
          <label className="field">
            <span>Name</span>
            <input type="text" value={name} onChange={(e) => setName(e.target.value)} placeholder="Alex Customer" />
          </label>
          <label className="field">
            <span>Email</span>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="alex@example.com"
            />
          </label>
          <button type="submit" className="btn btn-primary" disabled={creating}>
            <Plus size={16} /> Add customer
          </button>
        </form>

        {customers === null ? (
          <p className="muted">Loading...</p>
        ) : customers.length === 0 ? (
          <div className="empty-state">No customers yet. Add your first one above.</div>
        ) : (
          <ul className="record-list">
            {customers.map((customer) => (
              <li key={customer.id}>
                <div className="record-info">
                  <strong>{customer.name}</strong>
                  <span>{customer.email}</span>
                </div>
                <span className="muted">{customer.activeSubscriptionCount} active subscription(s)</span>
                <div className="record-actions">
                  <button
                    type="button"
                    className="btn btn-danger"
                    onClick={() => handleDelete(customer)}
                    aria-label={`Delete ${customer.name}`}
                  >
                    <Trash2 size={16} />
                  </button>
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>
    </>
  );
}
