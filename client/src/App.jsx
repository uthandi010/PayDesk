import { Suspense, lazy } from "react";
import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import { AuthProvider } from "./auth/AuthContext";
import { ProtectedRoute } from "./auth/ProtectedRoute";
import { LoginPage } from "./pages/LoginPage";
import { RegisterPage } from "./pages/RegisterPage";
import { CustomersPage } from "./pages/CustomersPage";
import { PlansPage } from "./pages/PlansPage";
import { SubscriptionsPage } from "./pages/SubscriptionsPage";
import { InvoicesPage } from "./pages/InvoicesPage";
import { PublicInvoicePage } from "./pages/PublicInvoicePage";

// Recharts is the single heaviest dependency in the app - only the
// dashboard needs it, so keep it out of the initial bundle.
const DashboardPage = lazy(() => import("./pages/DashboardPage").then((m) => ({ default: m.DashboardPage })));

function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route path="/register" element={<RegisterPage />} />
          <Route path="/invoice/:token" element={<PublicInvoicePage />} />
          <Route
            path="/dashboard"
            element={
              <ProtectedRoute>
                <Suspense fallback={<div className="page-content">Loading...</div>}>
                  <DashboardPage />
                </Suspense>
              </ProtectedRoute>
            }
          />
          <Route
            path="/customers"
            element={
              <ProtectedRoute>
                <CustomersPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/plans"
            element={
              <ProtectedRoute>
                <PlansPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/subscriptions"
            element={
              <ProtectedRoute>
                <SubscriptionsPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/invoices"
            element={
              <ProtectedRoute>
                <InvoicesPage />
              </ProtectedRoute>
            }
          />
          <Route path="/" element={<Navigate to="/dashboard" replace />} />
          <Route path="*" element={<Navigate to="/dashboard" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}

export default App;
