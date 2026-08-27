import React, { useState, useEffect } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../firebase/auth';
import { db } from '../firebase/config';
import { collection, query, orderBy, limit, onSnapshot } from 'firebase/firestore';
import {
  LayoutDashboard,
  Store,
  Users,
  Pill,
  MessageSquare,
  LogOut,
  Bell,
  User as UserIcon,
  Settings
} from 'lucide-react';

const Layout: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const location = useLocation();
  const navigate = useNavigate();
  const { logout, user, profile } = useAuth();
  const [showNotifications, setShowNotifications] = useState(false);
  const [showProfileMenu, setShowProfileMenu] = useState(false);
  const [notifications, setNotifications] = useState<any[]>([]);

  useEffect(() => {
    const q = query(collection(db, 'reportes_incidencias'), orderBy('fecha', 'desc'), limit(5));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const docs = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      setNotifications(docs);
    });
    return () => unsubscribe();
  }, []);

  const handleLogout = async () => {
    try {
      await logout();
      navigate('/login');
    } catch (error) {
      console.error("Error logging out:", error);
    }
  };

  const menuItems = [
    { icon: LayoutDashboard, label: 'Dashboard', path: '/' },
    { icon: Store, label: 'Farmacias', path: '/farmacias' },
    { icon: Users, label: 'Usuarios', path: '/usuarios' },
    { icon: Pill, label: 'Medicamentos', path: '/medicamentos' },
    { icon: MessageSquare, label: 'Soporte', path: '/soporte' },
  ];

  const adminInitial = profile?.nombre?.charAt(0).toUpperCase() || user?.email?.charAt(0).toUpperCase() || 'A';

  return (
    <div className="flex h-screen bg-gray-50 text-gray-900 font-sans">
      {/* Sidebar */}
      <aside className="w-64 bg-white border-r border-gray-200 flex flex-col">
        <div className="p-6 border-b border-gray-200">
          <h1 className="text-2xl font-bold text-green-600 flex items-center gap-2">
            <Pill className="w-8 h-8" />
            Medivida
          </h1>
          <p className="text-xs text-gray-500 mt-1 uppercase tracking-wider font-semibold">Admin Panel</p>
        </div>

        <nav className="flex-1 p-4 space-y-2">
          {menuItems.map((item) => {
            const Icon = item.icon;
            const isActive = location.pathname === item.path;
            return (
              <Link
                key={item.path}
                to={item.path}
                className={`flex items-center gap-3 px-4 py-3 rounded-xl transition-all ${
                  isActive
                    ? 'bg-green-50 text-green-600 shadow-sm'
                    : 'text-gray-500 hover:bg-gray-100'
                }`}
              >
                <Icon className="w-5 h-5" />
                <span className="font-medium">{item.label}</span>
              </Link>
            );
          })}
        </nav>

        <div className="p-4 border-t border-gray-200">
          <button
            onClick={handleLogout}
            className="flex items-center gap-3 px-4 py-3 w-full text-red-500 hover:bg-red-50 rounded-xl transition-all cursor-pointer"
          >
            <LogOut className="w-5 h-5" />
            <span className="font-medium">Cerrar Sesión</span>
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 flex flex-col overflow-hidden">
        {/* Topbar */}
        <header className="h-16 bg-white border-b border-gray-200 flex items-center justify-between px-8 relative">
          <h2 className="text-xl font-semibold">
            {menuItems.find(i => i.path === location.pathname)?.label || 'Panel'}
          </h2>
          <div className="flex items-center gap-4">
            {/* Notifications Bell */}
            <div className="relative">
              <button
                onClick={() => setShowNotifications(!showNotifications)}
                className={`p-2 rounded-lg transition-colors relative ${showNotifications ? 'bg-gray-100 text-green-600' : 'text-gray-400 hover:text-gray-600 hover:bg-gray-50'}`}
              >
                <Bell className="w-6 h-6" />
                {notifications.some(n => n.estado === 'pendiente') && (
                  <span className="absolute top-2 right-2 w-2 h-2 bg-red-500 rounded-full border-2 border-white"></span>
                )}
              </button>

              {showNotifications && (
                <div className="absolute right-0 mt-2 w-80 bg-white rounded-2xl shadow-xl border border-gray-100 z-50 animate-in fade-in zoom-in duration-200">
                  <div className="p-4 border-b border-gray-50 flex justify-between items-center">
                    <h4 className="font-bold text-sm">Notificaciones</h4>
                    <Link to="/soporte" onClick={() => setShowNotifications(false)} className="text-[10px] text-green-600 font-bold hover:underline">Ver todo</Link>
                  </div>
                  <div className="max-h-96 overflow-auto">
                    {notifications.length > 0 ? (
                      notifications.map((n) => (
                        <div
                          key={n.id}
                          className="p-4 border-b border-gray-50 hover:bg-gray-50 transition-colors cursor-pointer"
                          onClick={() => { navigate('/soporte'); setShowNotifications(false); }}
                        >
                          <div className="flex items-start gap-3">
                            <div className={`mt-1 w-2 h-2 rounded-full flex-shrink-0 ${n.estado === 'resuelto' ? 'bg-gray-300' : 'bg-green-500'}`} />
                            <div>
                              <p className="text-xs font-bold text-gray-800 line-clamp-1">{n.descripcion}</p>
                              <p className="text-[10px] text-gray-400 mt-1">{n.nombre_farmaco || 'Consulta de soporte'}</p>
                            </div>
                          </div>
                        </div>
                      ))
                    ) : (
                      <div className="p-8 text-center text-gray-400 text-xs">Sin notificaciones nuevas</div>
                    )}
                  </div>
                </div>
              )}
            </div>

            {/* Profile Menu */}
            <div className="relative">
              <button
                onClick={() => setShowProfileMenu(!showProfileMenu)}
                className={`flex items-center gap-2 p-1 pr-3 rounded-full transition-all border ${showProfileMenu ? 'bg-green-50 border-green-200' : 'border-transparent hover:bg-gray-50'}`}
              >
                <div className="h-8 w-8 bg-green-100 rounded-full flex items-center justify-center text-green-700 font-extrabold border border-green-200 shadow-sm">
                  {adminInitial}
                </div>
                <span className="text-xs font-bold text-gray-600 hidden md:block">{profile?.nombre || 'Admin'}</span>
              </button>

              {showProfileMenu && (
                <div className="absolute right-0 mt-2 w-56 bg-white rounded-2xl shadow-xl border border-gray-100 z-50 animate-in fade-in zoom-in duration-200 overflow-hidden">
                  <div className="p-4 bg-gray-50/50 border-b border-gray-100">
                    <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-1">Sesión Activa</p>
                    <p className="text-xs font-bold text-gray-700 truncate">{user?.email}</p>
                  </div>
                  <div className="p-2">
                    <button className="w-full flex items-center gap-3 px-3 py-2 text-sm text-gray-600 hover:bg-gray-50 rounded-xl transition-colors">
                      <UserIcon className="w-4 h-4" /> Mi Perfil
                    </button>
                    <button className="w-full flex items-center gap-3 px-3 py-2 text-sm text-gray-600 hover:bg-gray-50 rounded-xl transition-colors">
                      <Settings className="w-4 h-4" /> Configuración
                    </button>
                    <div className="h-px bg-gray-100 my-2 mx-2" />
                    <button
                      onClick={handleLogout}
                      className="w-full flex items-center gap-3 px-3 py-2 text-sm text-red-500 hover:bg-red-50 rounded-xl transition-colors font-bold"
                    >
                      <LogOut className="w-4 h-4" /> Cerrar Sesión
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>
        </header>

        {/* Scrollable Area */}
        <div className="flex-1 overflow-auto p-8">
          {children}
        </div>
      </main>

      {/* Click outside to close menus */}
      {(showNotifications || showProfileMenu) && (
        <div
          className="fixed inset-0 z-40"
          onClick={() => { setShowNotifications(false); setShowProfileMenu(false); }}
        />
      )}
    </div>
  );
};

export default Layout;
