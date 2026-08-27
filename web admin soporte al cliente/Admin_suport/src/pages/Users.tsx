import React, { useEffect, useState } from 'react';
import { db } from '../firebase/config';
import { collection, getDocs, query, orderBy, doc, updateDoc, deleteDoc } from 'firebase/firestore';
import { User, Mail, Shield, Search, Trash2, Ban, CheckCircle, AlertTriangle } from 'lucide-react';

const Users: React.FC = () => {
  const [users, setUsers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = async () => {
    try {
      const q = query(collection(db, 'usuarios'), orderBy('nombre', 'asc'));
      const querySnapshot = await getDocs(q);
      setUsers(querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
    } catch (error) {
      console.error("Error fetching users:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleSuspend = async (userId: string, currentStatus: boolean) => {
    const action = currentStatus ? 'activar' : 'suspender';
    if (!confirm(`¿Estás seguro de que deseas ${action} a este usuario?`)) return;

    try {
      const userRef = doc(db, 'usuarios', userId);
      await updateDoc(userRef, {
        suspendido: !currentStatus
      });
      fetchUsers(); // Recargar lista
    } catch (error) {
      alert("Error al cambiar estado del usuario");
    }
  };

  const handleDelete = async (userId: string) => {
    if (!confirm("¡ADVERTENCIA! Esta acción eliminará al usuario permanentemente de la base de datos. ¿Deseas continuar?")) return;

    try {
      await deleteDoc(doc(db, 'usuarios', userId));
      fetchUsers(); // Recargar lista
    } catch (error) {
      alert("Error al eliminar usuario");
    }
  };

  const filteredUsers = users.filter(u =>
    u.nombre?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    u.email?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <h3 className="text-xl font-bold text-gray-800">Gestión de Usuarios</h3>
          <p className="text-sm text-gray-500">Control de accesos, suspensiones y bajas del sistema.</p>
        </div>
        <div className="relative w-full md:w-96">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            type="text"
            placeholder="Buscar por nombre o correo..."
            className="w-full pl-10 pr-4 py-3 bg-white border border-gray-200 rounded-2xl outline-none focus:ring-2 focus:ring-green-500 shadow-sm transition-all"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
      </div>

      {loading ? (
        <div className="flex justify-center py-20">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-green-600"></div>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredUsers.map((user) => (
            <div key={user.id} className={`bg-white p-6 rounded-3xl border transition-all relative group ${user.suspendido ? 'border-red-100 bg-red-50/10' : 'border-gray-100 shadow-sm hover:shadow-md'}`}>

              {user.suspendido && (
                <div className="absolute top-4 right-20 flex items-center gap-1 bg-red-100 text-red-600 px-2 py-1 rounded-lg text-[10px] font-bold uppercase animate-pulse">
                  <Ban className="w-3 h-3" /> Suspendido
                </div>
              )}

              <div className="flex items-start justify-between mb-4">
                <div className={`w-12 h-12 rounded-2xl flex items-center justify-center ${user.suspendido ? 'bg-red-100 text-red-600' : 'bg-green-50 text-green-600'}`}>
                  <User className="w-6 h-6" />
                </div>
                <div className="flex flex-col items-end">
                  <span className={`px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider ${
                    user.rol === 'farmaceutico' ? 'bg-blue-100 text-blue-700' : 'bg-purple-100 text-purple-700'
                  }`}>
                    {user.rol || 'Cliente'}
                  </span>
                </div>
              </div>

              <h4 className="font-bold text-lg text-gray-800 mb-1">{user.nombre || 'Usuario sin nombre'}</h4>
              <div className="space-y-2 text-sm text-gray-500 mb-6">
                <p className="flex items-center gap-2 truncate"><Mail className="w-4 h-4" /> {user.email || 'Sin correo'}</p>
                <p className="flex items-center gap-2"><Shield className="w-4 h-4 text-gray-300" /> <span className="font-mono text-[11px]">{user.id}</span></p>
              </div>

              <div className="pt-4 border-t border-gray-50 flex justify-between items-center gap-2">
                <button
                  onClick={() => handleSuspend(user.id, user.suspendido)}
                  className={`flex-1 flex items-center justify-center gap-2 py-2 rounded-xl text-xs font-bold transition-colors ${
                    user.suspendido
                    ? 'bg-green-100 text-green-700 hover:bg-green-200'
                    : 'bg-orange-50 text-orange-600 hover:bg-orange-100'
                  }`}
                >
                  {user.suspendido ? <CheckCircle className="w-4 h-4" /> : <Ban className="w-4 h-4" />}
                  {user.suspendido ? 'Activar' : 'Suspender'}
                </button>

                <button
                  onClick={() => handleDelete(user.id)}
                  className="p-2 bg-red-50 text-red-400 hover:bg-red-500 hover:text-white rounded-xl transition-all shadow-sm"
                  title="Eliminar permanentemente"
                >
                  <Trash2 className="w-5 h-5" />
                </button>
              </div>
            </div>
          ))}
          {filteredUsers.length === 0 && (
            <div className="col-span-full text-center py-20 text-gray-400">
              <AlertTriangle className="w-12 h-12 mx-auto mb-4 opacity-20" />
              <p>No se encontraron usuarios que coincidan con la búsqueda.</p>
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default Users;
