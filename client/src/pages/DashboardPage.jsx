import { useEffect, useState } from "react";
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, LabelList } from "recharts";
import { NavBar } from "../components/NavBar";
import * as dashboardApi from "../api/dashboard";
import { ApiError } from "../api/client";
import { formatCents } from "../utils/money";

function formatMonth(key) {
  const [year, month] = key.split("-");
  return new Date(Number(year), Number(month) - 1, 1).toLocaleDateString(undefined, {
    month: "short",
    year: "2-digit",
  });
}

function RevenueTooltip({ active, payload }) {
  if (!active || !payload?.length) return null;
  const row = payload[0].payload;
  return (
    <div className="chart-tooltip">
      <div className="chart-tooltip-label">{formatMonth(row.month)}</div>
      <div className="chart-tooltip-value">{formatCents(row.amountCents)}</div>
    </div>
  );
}

export function DashboardPage() {
  const [summary, setSummary] = useState(null);
  const [error, setError] = useState(null);

  useEffect(() => {
    dashboardApi
      .getDashboardSummary()
      .then(setSummary)
      .catch((err) => setError(err instanceof ApiError ? err.message : "Failed to load the dashboard."));
  }, []);

  if (error) {
    return (
      <div>
        <NavBar />
        <main className="page-content">
          <div className="form-error" role="alert">
            {error}
          </div>
        </main>
      </div>
    );
  }

  if (!summary) {
    return (
      <div>
        <NavBar />
        <main className="page-content">
          <p className="muted">Loading dashboard...</p>
        </main>
      </div>
    );
  }

  return (
    <div>
      <NavBar />
      <main className="page-content">
        <div className="page-header">
          <div>
            <h1>Dashboard</h1>
            <p>Your business at a glance.</p>
          </div>
        </div>

        <div className="stat-tiles">
          <div className="stat-tile">
            <span className="stat-label">MRR</span>
            <span className="stat-value">{formatCents(summary.mrrCents)}</span>
          </div>
          <div className="stat-tile">
            <span className="stat-label">Active subscriptions</span>
            <span className="stat-value">{summary.activeSubscriptions}</span>
          </div>
          <div className="stat-tile">
            <span className="stat-label">Customers</span>
            <span className="stat-value">{summary.totalCustomers}</span>
          </div>
          <div className="stat-tile">
            <span className="stat-label">Outstanding invoices</span>
            <span className="stat-value">{summary.outstandingInvoices}</span>
          </div>
        </div>

        <div className="chart-card">
          <h2>Revenue, last {summary.revenueByMonth.length} months</h2>
          <ResponsiveContainer width="100%" height={240}>
            <BarChart data={summary.revenueByMonth} margin={{ top: 20, right: 12, bottom: 0, left: 0 }}>
              <CartesianGrid stroke="var(--chart-grid)" vertical={false} />
              <XAxis
                dataKey="month"
                tickFormatter={formatMonth}
                tick={{ fill: "var(--chart-muted)", fontSize: 12 }}
                axisLine={{ stroke: "var(--chart-axis)" }}
                tickLine={false}
              />
              <YAxis
                tickFormatter={(v) => formatCents(v)}
                tick={{ fill: "var(--chart-muted)", fontSize: 12 }}
                axisLine={false}
                tickLine={false}
                width={64}
              />
              <Tooltip content={<RevenueTooltip />} cursor={{ fill: "var(--chart-grid)" }} />
              <Bar dataKey="amountCents" fill="var(--chart-series-1)" radius={[4, 4, 0, 0]}>
                <LabelList
                  dataKey="amountCents"
                  position="top"
                  formatter={(v) => (v > 0 ? formatCents(v) : "")}
                  fill="var(--chart-text)"
                  fontSize={12}
                />
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>
      </main>
    </div>
  );
}
