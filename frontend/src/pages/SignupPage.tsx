import { useState, type FormEvent } from "react";
import { Link, useNavigate } from "react-router-dom";
import { signUp } from "aws-amplify/auth";
import { getErrorMessage } from "../lib/errors";

export function SignupPage() {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const navigate = useNavigate();

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setIsSubmitting(true);
    try {
      const { nextStep } = await signUp({
        username: email,
        password,
        options: { userAttributes: { email, name } },
      });

      if (nextStep.signUpStep === "CONFIRM_SIGN_UP") {
        navigate("/confirm-signup", { state: { email } });
        return;
      }

      navigate("/login");
    } catch (err) {
      setError(getErrorMessage(err));
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <form className="auth-form" onSubmit={handleSubmit}>
      <h1>Crear cuenta</h1>
      <label>
        Nombre
        <input
          value={name}
          onChange={(e) => setName(e.target.value)}
          required
          autoFocus
        />
      </label>
      <label>
        Email
        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
        />
      </label>
      <label>
        Contraseña
        <input
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
          minLength={12}
        />
      </label>
      {error && <p className="error-text">{error}</p>}
      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? "Creando…" : "Crear cuenta"}
      </button>
      <p className="auth-links">
        <Link to="/login">Ya tengo cuenta</Link>
      </p>
    </form>
  );
}
