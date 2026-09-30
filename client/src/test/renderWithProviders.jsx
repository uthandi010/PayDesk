import { render } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { AuthProvider } from "../auth/AuthContext";

// Every authenticated page renders <NavBar/>, which calls useAuth() and
// react-router-dom hooks - so page-level tests need both a Router and an
// AuthProvider around them, not just the component under test.
export function renderWithProviders(ui, { route = "/" } = {}) {
  return render(
    <MemoryRouter initialEntries={[route]}>
      <AuthProvider>{ui}</AuthProvider>
    </MemoryRouter>
  );
}
