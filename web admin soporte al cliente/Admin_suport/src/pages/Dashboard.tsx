import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  collection,
  getDocs,
  query,
  limit,
  orderBy
} from 'firebase/firestore';
import { db } from '../firebase/config';
import {
  Users,
  Store,
  Pill,
  AlertTriangle,
  TrendingUp,
  ArrowUpRight,
  MessageSquare
} from 'lucide-react';

const StatCard = ({ icon: Icon, label, value, color, loading }: any) => (
  <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm hover:shadow-md transition-shadow">
    <div className="flex justify-between items-start mb-4">
      <div className={`p-3 rounded-xl ${color} bg-opacity-10`}>
        <Icon className={`w-6 h-6 ${color.replace('bg-', 'text-')}`} />
      </div>
      <span className="flex items-center text-xs font-bold text-green-500 bg-green-50 px-2 py-1 rounded-lg">
        Activo <ArrowUpRight className="w-3 h-3 ml-1" />
      </span>
    </div>
    <p className="text-gray-500 text-sm font-medium">{label}</p>
    {loading ? (
      <div className="h-8 w-16 bg-gray-100 animate-pulse rounded mt-1"></div>
    ) : (
      <h3 className="text-2xl font-bold mt-1">{value}</h3>
    )}
  </div>
);

const Dashboard: React.FC = () => {
  const [stats, setStats] = useState({
    users: 0,
    pharmacies: 0,
    medicines: 0,
    reports: 0
  });
  const [recentActivity, setRecentActivity] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const [usersSnap, pharmaciesSnap, medicinesSnap, reportsSnap] = await Promise.all([
          getDocs(collection(db, "usuarios")),
          getDocs(collection(db, "farmacias")),
          getDocs(collection(db, "medicamentos_maestros")),
          getDocs(collection(db, "reportes_incidencias"))
        ]);

        setStats({
          users: usersSnap.size,
          pharmacies: pharmaciesSnap.size,
          medicines: medicinesSnap.size,
          reports: reportsSnap.size
        });

        setRecentActivity(pharmaciesSnap.docs.slice(0, 4).map(doc => ({
          id: doc.id,
          ...doc.data()
        })));
      } catch (error) {
        console.error("Error fetching dashboard stats:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchStats();
  }, []);

  return (
    <div className="space-y-8">
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard
          icon={Users}
          label="Usuarios Totales"
          value={stats.users.toLocaleString()}
          color="bg-blue-500"
          loading={loading}
        />
        <StatCard
          icon={Store}
          label="Farmacias"
          value={stats.pharmacies.toLocaleString()}
          color="bg-green-500"
          loading={loading}
        />
        <StatCard
          icon={Pill}
          label="Medicamentos Maestro"
          value={stats.medicines.toLocaleString()}
          color="bg-purple-500"
          loading={loading}
        />
        <StatCard
          icon={AlertTriangle}
          label="Reportes de Usuarios"
          value={stats.reports}
          color="bg-orange-500"
          loading={loading}
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm">
          <div className="flex justify-between items-center mb-6">
            <h3 className="font-bold text-lg">Últimas Farmacias Registradas</h3>
            <button className="text-green-600 text-sm font-semibold hover:underline">Ver todo</button>
          </div>
          <div className="space-y-4">
            {recentActivity.map((farmacia) => (
              <div key={farmacia.id} className="flex items-center gap-4 p-3 hover:bg-gray-50 rounded-xl transition-colors">
                <div className="w-10 h-10 rounded-full bg-green-50 flex items-center justify-center">
                  <Store className="w-5 h-5 text-green-600" />
                </div>
                <div className="flex-1">
                  <p className="text-sm font-medium">{farmacia.nombre}</p>
                  <p className="text-xs text-gray-400">{farmacia.direccion || 'Sin dirección registrada'}</p>
                </div>
              </div>
            ))}
            {recentActivity.length === 0 && !loading && (
              <p className="text-center text-gray-400 py-4">No hay actividad reciente.</p>
            )}
          </div>
        </div>

        <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm">
          <h3 className="font-bold text-lg mb-6">Panel de Control Maestro</h3>
          <div className="grid grid-cols-2 gap-4">
            <button
              onClick={() => navigate('/medicamentos')}
              className="p-4 bg-green-50 text-green-700 rounded-xl border border-green-100 hover:bg-green-100 transition-colors text-left group cursor-pointer"
            >
              <Pill className="mb-2 group-hover:scale-110 transition-transform" />
              <p className="font-bold">Catalogo Global</p>
              <p className="text-xs opacity-70">Gestionar medicamentos</p>
            </button>
            <button
              onClick={() => navigate('/soporte')}
              className="p-4 bg-blue-50 text-blue-700 rounded-xl border border-blue-100 hover:bg-blue-100 transition-colors text-left group cursor-pointer"
            >
              <MessageSquare className="mb-2 group-hover:scale-110 transition-transform" />
              <p className="font-bold">Centro de Soporte</p>
              <p className="text-xs opacity-70">Tickets de ayuda</p>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
