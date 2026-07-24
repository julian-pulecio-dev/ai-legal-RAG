import { useState, type FormEvent } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { confirmSignUp, resendSignUpCode } from "aws-amplify/auth";
import { getErrorMessage } from "../lib/errors";

export function ConfirmSignupPage() {
  const location = useLocation();
  const navigate = useNavigate();
  const [email, setEmail] = useState(
    (location.state as { email?: string } | null)?.email ?? "",
  );
  const [code, setCode] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [info, setInfo] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setIsSubmitting(true);
    try {
      await confirmSignUp({ username: email, confirmationCode: code });
      navigate("/login", { state: { confirmed: true } });
    } catch (err) {
      setError(getErrorMessage(err));
    } finally {
      setIsSubmitting(false);
    }
  }

  async function handleResend() {
    setError(null);
    setInfo(null);
    try {
      await resendSignUpCode({ username: email });
      setInfo("Código reenviado. Revisa tu email.");
    } catch (err) {
      setError(getErrorMessage(err));
    }
  }

  return (
    <form className="auth-form" onSubmit={handleSubmit}>
      <h1>Confirmar cuenta</h1>
      <label>
        Email
        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
          autoFocus
        />
      </label>
      <label>
        Código de verificación
        <input value={code} onChange={(e) => setCode(e.target.value)} required />
      </label>
      {error && <p className="error-text">{error}</p>}
      {info && <p className="info-text">{info}</p>}
      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? "Confirmando…" : "Confirmar"}
      </button>
      <p className="auth-links">
        <button type="button" className="link-button" onClick={handleResend}>
          Reenviar código
        </button>
        <Link to="/login">Volver a iniciar sesión</Link>
      </p>
    </form>
  );
}
