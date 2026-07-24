import { Amplify } from "aws-amplify";

const userPoolId = import.meta.env.VITE_COGNITO_USER_POOL_ID;
const userPoolClientId = import.meta.env.VITE_COGNITO_APP_CLIENT_ID;

if (!userPoolId || !userPoolClientId) {
  throw new Error(
    "Faltan VITE_COGNITO_USER_POOL_ID / VITE_COGNITO_APP_CLIENT_ID. " +
      "Copia .env.example a .env y completa los valores del `terraform output` " +
      "(backend/terraform).",
  );
}

// Sin Identity Pool: el backend solo emite JWT del User Pool para
// autenticar contra el API Gateway propio (ver backend/terraform/modules/cognito/main.tf).
Amplify.configure({
  Auth: {
    Cognito: {
      userPoolId,
      userPoolClientId,
      loginWith: {
        email: true,
      },
    },
  },
});
