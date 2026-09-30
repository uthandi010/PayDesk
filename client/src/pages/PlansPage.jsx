import { useEffect, useState } from "react";
import { Plus, Trash2 } from "lucide-react";
import { NavBar } from "../components/NavBar";
import * as plansApi from "../api/plans";
import { ApiError } from "../api/client";
import { formatCents } from "../utils/money";

export function PlansPage() {
  const [plans, setPlans] = useState(null);
  const [error, setError] = useState(null);
  const [name, setName] = useState("");
  const [amount, setAmount] = useState("");
  const [interval, setInterval_] = useState("month");
  const [creating, setCreating] = useState(false);

  useEffect(() => {
    plansApi
      .listPlans()
      .then(setPlans)
      .catch((err) => setError(err instanceof ApiError ? err.message : "Failed to load plans."));
  }, []);

  async function handleCreate(event) {
    event.preventDefault();
    const cents = Math.round(Number(amount) * 100);
    if (!name.trim() || !cents || cents <= 0) return;

    setCreating(true);
    setError(null);
    try {
      const plan = await plansApi.createPlan({ name: name.trim(), amount_cents: cents, interval });
      setPlans((current) => [plan, ...current]);
      setName("");
      setAmount("");
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Could not create that plan.");
    } finally {
      setCreating(false);
    }
  }

  async function handleDelete(plan) {
    try {
      await plansApi.deletePlan(plan.id);
      setPlans((current) => current.filter((p) => p.id !== plan.id));
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Could not delete that plan.");
    }
  }

  return (
    <>
      <NavBar />
      <div className="page-content">
        <div className="page-header">
          <div>
            <h1>Plans</h1>
            <p>What customers subscribe to.</p>
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
            <input type="text" value={name} onChange={(e) => setName(e.target.value)} placeholder="Pro" />
          </label>
          <label className="field">
            <span>Price (USD)</span>
            <input
              type="number"
              min="0.01"
              step="0.01"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              placeholder="29.00"
            />
          </label>
          <label className="field">
            <span>Billed</span>
            <select value={interval} onChange={(e) => setInterval_(e.target.value)}>
              <option value="month">Monthly</option>
              <option value="year">Yearly</option>
            </select>
          </label>
          <button type="submit" className="btn btn-primary" disabled={creating}>
            <Plus size={16} /> Add plan
          </button>
        </form>

        {plans === null ? (
          <p className="muted">Loading...</p>
        ) : plans.length === 0 ? (
          <div className="empty-state">No plans yet. Add your first one above.</div>
        ) : (
          <ul className="record-list">
            {plans.map((plan) => (
              <li key={plan.id}>
                <div className="record-info">
                  <strong>{plan.name}</strong>
                  <span>
                    {formatCents(plan.amountCents)} / {plan.interval}
                  </span>
                </div>
                <span className="muted">{plan.subscriptionCount} subscriber(s)</span>
                <div className="record-actions">
                  <button
                    type="button"
                    className="btn btn-danger"
                    onClick={() => handleDelete(plan)}
                    aria-label={`Delete ${plan.name}`}
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
