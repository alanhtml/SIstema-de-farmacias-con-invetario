import React, { createContext, useContext, useEffect, useState } from 'react';
import {
  onAuthStateChanged,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signOut,
  type User
} from 'firebase/auth';
import { auth, db } from './config';
import { doc, getDoc, setDoc, serverTimestamp } from 'firebase/firestore';

interface AuthContextType {
  user: User | null;
  profile: any | null;
  loading: boolean;
  login: (email: string, pass: string) => Promise<void>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | null>(null);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<any | null>(null);
  const [loading, setLoading] = useState(true);

  const MASTER_EMAIL = "guido1@gmail.com";

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
      if (firebaseUser) {
        const userData = await ensureUserProfile(firebaseUser);
        setProfile(userData);
        setUser(firebaseUser);
      } else {
        setUser(null);
        setProfile(null);
      }
      setLoading(false);
    });
    return unsubscribe;
  }, []);

  const ensureUserProfile = async (firebaseUser: User) => {
    try {
      const userRef = doc(db, 'usuarios', firebaseUser.uid);
      const userSnap = await getDoc(userRef);

      if (!userSnap.exists()) {
        console.log("Primer inicio detectado: Creando perfil en Firestore...");
        const newProfile = {
          uid: firebaseUser.uid,
          nombre: firebaseUser.email === MASTER_EMAIL ? "Administrador Maestro" : "Usuario Administrativo",
          email: firebaseUser.email,
          rol: firebaseUser.email === MASTER_EMAIL ? 'master_admin' : 'soporte',
          suspendido: false,
          createdAt: serverTimestamp()
        };
        await setDoc(userRef, newProfile);
        return newProfile;
      }
      return userSnap.data();
    } catch (error) {
      console.error("Error al asegurar perfil:", error);
      return null;
    }
  };

  const login = async (email: string, pass: string) => {
    try {
      await signInWithEmailAndPassword(auth, email, pass);
    } catch (error: any) {
      // SI ES EL ADMIN MAESTRO Y NO EXISTE O TIENE ERROR DE CREDENCIALES (PRIMERA VEZ)
      if (email === MASTER_EMAIL && (error.code === 'auth/user-not-found' || error.code === 'auth/invalid-credential')) {
        try {
          console.log("Creando cuenta maestra inicial...");
          await createUserWithEmailAndPassword(auth, email, pass);
        } catch (regError: any) {
          // Si el error es que ya existe pero la clave está mal, lanzamos el error original
          if (regError.code === 'auth/email-already-in-use') throw error;
          throw regError;
        }
      } else {
        throw error;
      }
    }
  };

  const logout = async () => {
    await signOut(auth);
  };

  return (
    <AuthContext.Provider value={{ user, profile, loading, login, logout }}>
      {!loading && children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) throw new Error("useAuth must be used within AuthProvider");
  return context;
};
