import { useEffect, useState } from "react";
import { RotateCw, Download } from "lucide-react";
import { NavBar } from "../components/NavBar";
import * as invoicesApi from "../api/invoices";
import { downloadInvoicePdf, ApiError } from "../api/client";
import { formatCents } from "../utils/money";

export function InvoicesPage() {
  const [invoices, setInvoices] = useState(null);
  const [error, setError] = useState(null);
  const [busyId, setBusyId] = useState(null);

  useEffect(() => {
    invoicesApi
      .listInvoices()
      .then(setInvoices)
      .catch((err) => setError(err instanceof ApiError ? err.message : "Failed to load invoices."));
  }, []);

  async function handleRetry(invoice) {
    setBusyId(invoice.id);
    setError(null);
    try {
      const updated = await invoicesApi.retryInvoice(invoice.id);
      setInvoices((current) => current.map((i) => (i.id === updated.id ? { ...i, ...updated } : i)));
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Could not retry that invoice.");
    } finally {
      setBusyId(null);
    }
  }

  async function handleDownload(invoice) {
    try {
      await downloadInvoicePdf(invoice.id);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Could not download that invoice.");
    }
  }

  return (
    <>
      <NavBar />
      <div className="page-content">
        <div className="page-header">
          <div>
            <h1>Invoices</h1>
            <p>Every bill sent to a customer, and whether it's been paid.</p>
          </div>
        </div>

        {error && (
          <div className="form-error" role="alert">
            {error}
          </div>
        )}

        {invoices === null ? (
          <p className="muted">Loading...</p>
        ) : invoices.length === 0 ? (
          <div className="empty-state">No invoices yet.</div>
        ) : (
          <ul className="record-list">
            {invoices.map((invoice) => (
              <li key={invoice.id}>
                <div className="record-info">
                  <strong>
                    {invoice.customer.name} &middot; {formatCents(invoice.amountCents)}
                  </strong>
                  <span>
                    {invoice.plan.name} &middot; due {new Date(invoice.dueDate).toLocaleDateString()}
                    {invoice.overdue && " (overdue)"}
                  </span>
                </div>
                <span className={`badge badge-${invoice.status}`}>{invoice.status}</span>
                <div className="record-actions">
                  {invoice.status === "open" && (
                    <button
                      type="button"
                      className="btn btn-secondary btn-sm"
                      onClick={() => handleRetry(invoice)}
                      disabled={busyId === invoice.id}
                    >
                      <RotateCw size={14} /> Retry charge
                    </button>
                  )}
                  <button
                    type="button"
                    className="btn btn-ghost btn-sm"
                    onClick={() => handleDownload(invoice)}
                    aria-label="Download PDF"
                  >
                    <Download size={14} /> PDF
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
