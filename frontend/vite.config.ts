import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// El puerto 5173 debe coincidir con `cors_allowed_origins` en
// backend/terraform/variables.tf para que el API Gateway acepte requests
// del dev server.
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
  },
});
