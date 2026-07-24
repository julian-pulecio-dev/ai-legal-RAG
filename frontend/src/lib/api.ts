import { fetchAuthSession } from "aws-amplify/auth";

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL;

/**
 * Fetch autenticado contra el API Gateway: adjunta el access token de la
 * sesión de Cognito como Bearer token, tal como espera el JWT authorizer
 * (backend/terraform/modules/api_gateway/main.tf).
 */
export async function authFetch(
  path: string,
  init: RequestInit = {},
): Promise<Response> {
  const session = await fetchAuthSession();
  const token = session.tokens?.accessToken?.toString();

  if (!token) {
    throw new Error("No hay una sesión activa.");
  }

  const headers = new Headers(init.headers);
  headers.set("Authorization", `Bearer ${token}`);

  return fetch(`${API_BASE_URL}${path}`, { ...init, headers });
}
