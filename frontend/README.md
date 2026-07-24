# Frontend

React + Vite + TypeScript, con login/registro contra el User Pool de Cognito
definido en `backend/terraform` (usa [AWS Amplify](https://docs.amplify.aws/react/build-a-backend/auth/)
como cliente de auth porque el App Client de Cognito solo permite el flujo
SRP — Amplify implementa ese protocolo; no hay Identity Pool, solo se
autentica contra la API propia con los JWT del User Pool).

## Requisitos

- Node.js 20.19+ o 22.12+ (requerido por Vite 8)

## Setup

1. Aplicar el Terraform del backend (`cd ../backend/terraform && terraform apply`)
   y obtener los outputs:

   ```bash
   cd ../backend/terraform
   terraform output
   ```

2. Copiar `.env.example` a `.env` y completar con esos valores:

   ```bash
   cp .env.example .env
   ```

   - `VITE_COGNITO_USER_POOL_ID` ← `cognito_user_pool_id`
   - `VITE_COGNITO_APP_CLIENT_ID` ← `cognito_app_client_id`
   - `VITE_API_BASE_URL` ← `api_endpoint`

3. Instalar dependencias y levantar el dev server:

   ```bash
   npm install
   npm run dev
   ```

   Corre en `http://localhost:5173`, que ya está incluido por defecto en
   `cors_allowed_origins` del Terraform.

## Estructura

- `src/amplifyConfig.ts` — configura Amplify con el User Pool/App Client.
- `src/context/AuthContext.tsx` — sesión actual (usuario, loading, sign out),
  se sincroniza con eventos de Amplify (`Hub`).
- `src/routes/ProtectedRoute.tsx` — redirige a `/login` si no hay sesión.
- `src/pages/` — `LoginPage`, `SignupPage`, `ConfirmSignupPage` (código de
  verificación por email), `ForgotPasswordPage` (reset con código),
  `DashboardPage` (ejemplo de pantalla protegida).
- `src/lib/api.ts` — `authFetch`, helper para llamar al API Gateway con el
  access token de la sesión (`Authorization: Bearer ...`). El backend aún no
  define rutas propias (`backend/terraform/modules/api_gateway/main.tf`), así
  que hoy no hay endpoints reales que consumir con este helper.

## Notas

- El login usa SRP (vía Amplify); no se envía la contraseña en texto plano.
- Si el usuario tiene MFA (TOTP) habilitado, el login pide el código
  correspondiente — la pantalla para *activar* MFA no está incluida, solo el
  desafío al iniciar sesión.
