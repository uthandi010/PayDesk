import { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import { CheckCircle2 } from "lucide-react";
import * as invoicesApi from "../api/invoices";
import { ApiError } from "../api/client";
import { formatCents } from "../utils/money";

export function PublicInvoicePage() {
  const { token } = useParams();
  const [invoice, setInvoice] = useState(null);
  const [error, setError] = useState(null);
  const [paying, setPaying] = useState(false);

  useEffect(() => {
    invoicesApi
      .getPublicInvoice(token)
      .then(setInvoice)
      .catch((err) => setError(err instanceof ApiError ? err.message : "That invoice link isn't valid."));
  }, [token]);

  async function handlePay() {
    setPaying(true);
    setError(null);
    try {
      const updated = await invoicesApi.payPublicInvoice(token);
      setInvoice(updated);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Payment could not be processed.");
    } finally {
      setPaying(false);
    }
  }

  if (error) {
    return (
      <div className="public-page">
        <div className="public-card auth-card">
          <div className="form-error" role="alert">
            {error}
          </div>
        </div>
      </div>
    );
  }

  if (!invoice) {
    return (
      <div className="public-page">
        <div className="public-card auth-card">
          <p className="muted">Loading invoice...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="public-page">
      <div className="public-card auth-card">
        <p className="muted">Invoice from {invoice.business}</p>
        <div className="invoice-amount">{formatCents(invoice.amountCents)}</div>
        <span className={`badge badge-${invoice.status}`}>{invoice.status}</span>

        <div style={{ marginTop: 20 }}>
          <div className="invoice-line">
            <span>Plan</span>
            <span>{invoice.plan.name}</span>
          </div>
          <div className="invoice-line">
            <span>Billed to</span>
            <span>{invoice.customer.name}</span>
          </div>
          <div className="invoice-line">
            <span>Due date</span>
            <span>{new Date(invoice.dueDate).toLocaleDateString()}</span>
          </div>
          {invoice.paidAt && (
            <div className="invoice-line">
              <span>Paid on</span>
              <span>{new Date(invoice.paidAt).toLocaleDateString()}</span>
            </div>
          )}
        </div>

        {invoice.status === "open" ? (
          <button type="button" className="btn btn-primary" style={{ width: "100%", marginTop: 20 }} onClick={handlePay} disabled={paying}>
            {paying ? "Processing..." : "Pay now"}
          </button>
        ) : invoice.status === "paid" ? (
          <p style={{ marginTop: 20, color: "var(--accent)", display: "flex", alignItems: "center", gap: 6 }}>
            <CheckCircle2 size={18} /> This invoice has been paid.
          </p>
        ) : null}
      </div>
    </div>
  );
}
