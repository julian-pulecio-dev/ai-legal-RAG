import { useState, type FormEvent } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { confirmSignIn, signIn, type SignInOutput } from "aws-amplify/auth";
import { useAuth } from "../context/AuthContext";
import { getErrorMessage } from "../lib/errors";

export function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [totpCode, setTotpCode] = useState("");
  const [needsTotp, setNeedsTotp] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const { refresh } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const redirectTo = (location.state as { from?: string } | null)?.from ?? "/";

  async function handleNextStep({ isSignedIn, nextStep }: SignInOutput) {
    if (isSignedIn) {
      await refresh();
      navigate(redirectTo, { replace: true });
      return;
    }

    if (nextStep.signInStep === "CONFIRM_SIGN_UP") {
      navigate("/confirm-signup", { state: { email } });
      return;
    }

    if (nextStep.signInStep === "CONFIRM_SIGN_IN_WITH_TOTP_CODE") {
      setNeedsTotp(true);
      return;
    }

    setError(`Paso de inicio de sesión no soportado: ${nextStep.signInStep}`);
  }

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setIsSubmitting(true);
    try {
      await handleNextStep(await signIn({ username: email, password }));
    } catch (err) {
      setError(getErrorMessage(err));
    } finally {
      setIsSubmitting(false);
    }
  }

  async function handleTotpSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setIsSubmitting(true);
    try {
      await handleNextStep(
        await confirmSignIn({ challengeResponse: totpCode }),
      );
    } catch (err) {
      setError(getErrorMessage(err));
    } finally {
      setIsSubmitting(false);
    }
  }

  if (needsTotp) {
    return (
      <form className="auth-form" onSubmit={handleTotpSubmit}>
        <h1>Código de autenticación</h1>
        <p>Ingresa el código de tu app de autenticación (TOTP).</p>
        <label>
          Código
          <input
            value={totpCode}
            onChange={(e) => setTotpCode(e.target.value)}
            required
            autoFocus
          />
        </label>
        {error && <p className="error-text">{error}</p>}
        <button type="submit" disabled={isSubmitting}>
          {isSubmitting ? "Verificando…" : "Verificar"}
        </button>
      </form>
    );
  }

  return (
    <form className="auth-form" onSubmit={handleSubmit}>
      <h1>Iniciar sesión</h1>
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
        Contraseña
        <input
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
        />
      </label>
      {error && <p className="error-text">{error}</p>}
      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? "Ingresando…" : "Ingresar"}
      </button>
      <p className="auth-links">
        <Link to="/forgot-password">¿Olvidaste tu contraseña?</Link>
        <Link to="/signup">Crear cuenta</Link>
      </p>
    </form>
  );
}
