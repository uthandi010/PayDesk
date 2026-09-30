import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";
import { ApiError } from "../api/client";

export function RegisterPage() {
  const { register } = useAuth();
  const navigate = useNavigate();
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState(null);
  const [submitting, setSubmitting] = useState(false);

  async function handleSubmit(event) {
    event.preventDefault();
    setError(null);

    if (!name.trim() || !email.trim() || password.length < 8) {
      setError("Name, email, and a password of at least 8 characters are required.");
      return;
    }

    setSubmitting(true);
    try {
      await register(name.trim(), email.trim(), password);
      navigate("/dashboard");
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Something went wrong. Please try again.");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="auth-page">
      <form className="auth-card" noValidate onSubmit={handleSubmit}>
        <h1>Create your PayDesk account</h1>
        <p className="auth-subtitle">Start billing customers in minutes, no payment processor required.</p>

        {error && (
          <div className="form-error" role="alert">
            {error}
          </div>
        )}

        <label className="field">
          <span>Your name</span>
          <input type="text" value={name} onChange={(e) => setName(e.target.value)} autoComplete="name" />
        </label>

        <label className="field">
          <span>Email</span>
          <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} autoComplete="email" />
        </label>

        <label className="field">
          <span>Password</span>
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            autoComplete="new-password"
          />
        </label>

        <button type="submit" className="btn btn-primary" disabled={submitting}>
          {submitting ? "Creating account..." : "Create account"}
        </button>

        <p className="auth-switch">
          Already have an account? <Link to="/login">Log in</Link>
        </p>
      </form>
    </div>
  );
}
