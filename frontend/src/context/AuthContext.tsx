import {
  createContext,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from "react";
import {
  fetchAuthSession,
  getCurrentUser,
  signOut as amplifySignOut,
} from "aws-amplify/auth";
import { Hub } from "aws-amplify/utils";

interface AuthUser {
  username: string;
  email?: string;
}

interface AuthContextValue {
  user: AuthUser | null;
  isLoading: boolean;
  signOut: () => Promise<void>;
  refresh: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

async function loadCurrentUser(): Promise<AuthUser | null> {
  try {
    const current = await getCurrentUser();
    const session = await fetchAuthSession();
    const email = session.tokens?.idToken?.payload.email as
      | string
      | undefined;
    return { username: current.username, email };
  } catch {
    return null;
  }
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  async function refresh() {
    setUser(await loadCurrentUser());
  }

  useEffect(() => {
    refresh().finally(() => setIsLoading(false));

    const unsubscribe = Hub.listen("auth", ({ payload }) => {
      if (payload.event === "signedIn" || payload.event === "signedOut") {
        refresh();
      }
    });

    return unsubscribe;
  }, []);

  async function signOut() {
    await amplifySignOut();
    setUser(null);
  }

  return (
    <AuthContext.Provider value={{ user, isLoading, signOut, refresh }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) {
    throw new Error("useAuth debe usarse dentro de <AuthProvider>");
  }
  return ctx;
}
