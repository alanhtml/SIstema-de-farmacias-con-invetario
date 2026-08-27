import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './firebase/auth';
import Layout from './components/Layout';
import Dashboard from './pages/Dashboard';
import Pharmacies from './pages/Pharmacies';
import Users from './pages/Users';
import Medicines from './pages/Medicines';
import Support from './pages/Support';
import Login from './pages/Login';

const AppRoutes = () => {
  const { user } = useAuth();

  if (!user) {
    return (
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="*" element={<Navigate to="/login" replace />} />
      </Routes>
    );
  }

  return (
    <Layout>
      <Routes>
        <Route path="/" element={<Dashboard />} />
        <Route path="/farmacias" element={<Pharmacies />} />
        <Route path="/usuarios" element={<Users />} />
        <Route path="/medicamentos" element={<Medicines />} />
        <Route path="/soporte" element={<Support />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </Layout>
  );
};

function App() {
  return (
    <AuthProvider>
      <Router>
        <AppRoutes />
      </Router>
    </AuthProvider>
  );
}

export default App;
