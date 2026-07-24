import { useAuth } from "../context/AuthContext";

export function DashboardPage() {
  const { user, signOut } = useAuth();

  return (
    <div className="dashboard">
      <h1>Bienvenido{user?.email ? `, ${user.email}` : ""}</h1>
      <p>Sesión iniciada correctamente contra el User Pool de Cognito.</p>
      <button onClick={() => void signOut()}>Cerrar sesión</button>
    </div>
  );
}
