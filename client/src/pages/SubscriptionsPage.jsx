import { useEffect, useState } from "react";
import { Plus, XCircle, RefreshCw } from "lucide-react";
import { NavBar } from "../components/NavBar";
import * as subscriptionsApi from "../api/subscriptions";
import * as customersApi from "../api/customers";
import * as plansApi from "../api/plans";
import { ApiError } from "../api/client";
import { formatCents } from "../utils/money";

export function SubscriptionsPage() {
  const [subscriptions, setSubscriptions] = useState(null);
  const [customers, setCustomers] = useState([]);
  const [plans, setPlans] = useState([]);
  const [customerId, setCustomerId] = useState("");
  const [planId, setPlanId] = useState("");
  const [error, setError] = useState(null);
  const [creating, setCreating] = useState(false);
  const [busyId, setBusyId] = useState(null);

  useEffect(() => {
    subscriptionsApi
      .listSubscriptions()
      .then(setSubscriptions)
      .catch((err) => setError(err instanceof ApiError ? err.message : "Failed to load subscriptions."));
    customersApi.listCustomers().then(setCustomers).catch(() => {});
    plansApi.listPlans().then(setPlans).catch(() => {});
  }, []);

  async function handleCreate(event) {
    event.preventDefault();
    if (!customerId || !planId) return;

    setCreating(true);
    setError(null);
    try {
      const subscription = await subscriptionsApi.createSubscription(customerId, planId);
      setSubscriptions((current) => [subscription, ...current]);
      setCustomerId("");
      setPlanId("");
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Could not create that subscription.");
    } finally {
      setCreating(false);
    }
  }

  async function handleCancel(subscription) {
    setBusyId(subscription.id);
    setError(null);
    try {
      const updated = await subscriptionsApi.cancelSubscription(subscription.id);
      setSubscriptions((current) => current.map((s) => (s.id === updated.id ? updated : s)));
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Could not cancel that subscription.");
    } finally {
      setBusyId(null);
    }
  }

  async function handleRenew(subscription) {
    setBusyId(subscription.id);
    setError(null);
    try {
      const updated = await subscriptionsApi.renewSubscription(subscription.id);
      setSubscriptions((current) => current.map((s) => (s.id === updated.id ? updated : s)));
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Could not renew that subscription.");
    } finally {
      setBusyId(null);
    }
  }

  return (
    <>
      <NavBar />
      <div className="page-content">
        <div className="page-header">
          <div>
            <h1>Subscriptions</h1>
            <p>Subscribing a customer bills their first period immediately.</p>
          </div>
        </div>

        {error && (
          <div className="form-error" role="alert">
            {error}
          </div>
        )}

        <form className="inline-form" noValidate onSubmit={handleCreate}>
          <label className="field">
            <span>Customer</span>
            <select value={customerId} onChange={(e) => setCustomerId(e.target.value)}>
              <option value="">Choose a customer...</option>
              {customers.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>
          </label>
          <label className="field">
            <span>Plan</span>
            <select value={planId} onChange={(e) => setPlanId(e.target.value)}>
              <option value="">Choose a plan...</option>
              {plans.map((p) => (
                <option key={p.id} value={p.id}>
                  {p.name} ({formatCents(p.amountCents)}/{p.interval})
                </option>
              ))}
            </select>
          </label>
          <button type="submit" className="btn btn-primary" disabled={creating}>
            <Plus size={16} /> Subscribe
          </button>
        </form>

        {subscriptions === null ? (
          <p className="muted">Loading...</p>
        ) : subscriptions.length === 0 ? (
          <div className="empty-state">No subscriptions yet.</div>
        ) : (
          <ul className="record-list">
            {subscriptions.map((sub) => (
              <li key={sub.id}>
                <div className="record-info">
                  <strong>
                    {sub.customer.name} &middot; {sub.plan.name}
                  </strong>
                  <span>
                    {formatCents(sub.plan.amountCents)}/{sub.plan.interval} &middot; renews{" "}
                    {new Date(sub.currentPeriodEnd).toLocaleDateString()}
                  </span>
                </div>
                <span className={`badge badge-${sub.status}`}>{sub.status.replace("_", " ")}</span>
                <div className="record-actions">
                  {sub.status !== "canceled" && (
                    <>
                      <button
                        type="button"
                        className="btn btn-secondary btn-sm"
                        onClick={() => handleRenew(sub)}
                        disabled={busyId === sub.id}
                      >
                        <RefreshCw size={14} /> Renew
                      </button>
                      <button
                        type="button"
                        className="btn btn-danger btn-sm"
                        onClick={() => handleCancel(sub)}
                        disabled={busyId === sub.id}
                      >
                        <XCircle size={14} /> Cancel
                      </button>
                    </>
                  )}
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>
    </>
  );
}
