import { useState, type FormEvent } from "react";
import { Link, useNavigate } from "react-router-dom";
import { confirmResetPassword, resetPassword } from "aws-amplify/auth";
import { getErrorMessage } from "../lib/errors";

export function ForgotPasswordPage() {
  const [step, setStep] = useState<"request" | "confirm">("request");
  const [email, setEmail] = useState("");
  const [code, setCode] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const navigate = useNavigate();

  async function handleRequest(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setIsSubmitting(true);
    try {
      const { nextStep } = await resetPassword({ username: email });
      if (nextStep.resetPasswordStep === "CONFIRM_RESET_PASSWORD_WITH_CODE") {
        setStep("confirm");
      } else {
        setError(`Paso no soportado: ${nextStep.resetPasswordStep}`);
      }
    } catch (err) {
      setError(getErrorMessage(err));
    } finally {
      setIsSubmitting(false);
    }
  }

  async function handleConfirm(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setIsSubmitting(true);
    try {
      await confirmResetPassword({
        username: email,
        confirmationCode: code,
        newPassword,
      });
      navigate("/login", { state: { passwordReset: true } });
    } catch (err) {
      setError(getErrorMessage(err));
    } finally {
      setIsSubmitting(false);
    }
  }

  if (step === "confirm") {
    return (
      <form className="auth-form" onSubmit={handleConfirm}>
        <h1>Nueva contraseña</h1>
        <label>
          Código de verificación
          <input
            value={code}
            onChange={(e) => setCode(e.target.value)}
            required
            autoFocus
          />
        </label>
        <label>
          Nueva contraseña
          <input
            type="password"
            value={newPassword}
            onChange={(e) => setNewPassword(e.target.value)}
            required
            minLength={12}
          />
        </label>
        {error && <p className="error-text">{error}</p>}
        <button type="submit" disabled={isSubmitting}>
          {isSubmitting ? "Guardando…" : "Guardar contraseña"}
        </button>
      </form>
    );
  }

  return (
    <form className="auth-form" onSubmit={handleRequest}>
      <h1>Recuperar contraseña</h1>
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
      {error && <p className="error-text">{error}</p>}
      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? "Enviando…" : "Enviar código"}
      </button>
      <p className="auth-links">
        <Link to="/login">Volver a iniciar sesión</Link>
      </p>
    </form>
  );
}
