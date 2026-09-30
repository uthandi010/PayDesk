import { Link, useNavigate, useLocation } from "react-router-dom";
import { LogOut, LayoutDashboard, Users, Package, Repeat, FileText } from "lucide-react";
import { useAuth } from "../auth/AuthContext";

const LINKS = [
  { to: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { to: "/customers", label: "Customers", icon: Users },
  { to: "/plans", label: "Plans", icon: Package },
  { to: "/subscriptions", label: "Subscriptions", icon: Repeat },
  { to: "/invoices", label: "Invoices", icon: FileText },
];

export function NavBar() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  function handleLogout() {
    logout();
    navigate("/login");
  }

  return (
    <header className="topnav">
      <Link to="/dashboard" className="topnav-brand">
        <span className="brand-mark">PD</span>
        PayDesk
      </Link>
      {user && (
        <nav className="topnav-links">
          {LINKS.map(({ to, label, icon: Icon }) => (
            <Link key={to} to={to} className={location.pathname.startsWith(to) ? "active" : ""}>
              <Icon size={16} /> {label}
            </Link>
          ))}
        </nav>
      )}
      {user && (
        <div className="topnav-actions">
          <span className="muted">{user.name}</span>
          <button type="button" className="btn btn-ghost" onClick={handleLogout}>
            <LogOut size={16} />
            Log out
          </button>
        </div>
      )}
    </header>
  );
}
