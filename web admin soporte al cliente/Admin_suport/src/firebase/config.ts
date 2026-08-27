import { initializeApp, getApps } from "firebase/app";
import { getFirestore } from "firebase/firestore";
import { getAuth } from "firebase/auth";

const firebaseConfig = {
  apiKey: "AIzaSyAuzU03ST2LgWDgffFB9W60lWUCOhCRWTY",
  authDomain: "farmacorp-d8251.firebaseapp.com",
  projectId: "farmacorp-d8251",
  storageBucket: "farmacorp-d8251.firebasestorage.app",
  messagingSenderId: "763530818666",
  appId: "1:763530818666:web:f3a3a19b4e883c45788613"
};

const app = getApps().length === 0 ? initializeApp(firebaseConfig) : getApps()[0];
export const db = getFirestore(app);
export const auth = getAuth(app);
