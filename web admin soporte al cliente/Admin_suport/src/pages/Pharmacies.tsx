import React, { useEffect, useState } from 'react';
import { db } from '../firebase/config';
import { collection, getDocs, doc, updateDoc, addDoc, serverTimestamp } from 'firebase/firestore';
import { Store, User, Phone, MapPin, Ban, CheckCircle, AlertCircle, Plus, X } from 'lucide-react';

const Pharmacies: React.FC = () => {
  const [pharmacies, setPharmacies] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);

  // Estado para nueva farmacia
  const [newPharmacy, setNewPharmacy] = useState({
    nombre: '',
    direccion: '',
    telefono: '',
    latitud: '',
    longitud: '',
    estado_activo: true
  });

  useEffect(() => {
    fetchPharmacies();
  }, []);

  const fetchPharmacies = async () => {
    setLoading(true);
    try {
      const farmaciasSnap = await getDocs(collection(db, 'farmacias'));
      const farmaciasData = farmaciasSnap.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));

      const usuariosSnap = await getDocs(collection(db, 'usuarios'));
      const farmaceuticos = usuariosSnap.docs
        .map(doc => doc.data())
        .filter(user => user.rol === 'farmaceutico');

      const mergedData = farmaciasData.map(farmacia => {
        const responsable = farmaceuticos.find(u => u.farmacia_id === farmacia.id);
        return {
          ...farmacia,
          farmaceutico_nombre: responsable ? responsable.nombre : 'Sin asignar'
        };
      });

      setPharmacies(mergedData);
    } catch (error) {
      console.error("Error fetching pharmacies:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleCreatePharmacy = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await addDoc(collection(db, 'farmacias'), {
        ...newPharmacy,
        createdAt: serverTimestamp()
      });
      setShowModal(false);
      setNewPharmacy({ nombre: '', direccion: '', telefono: '', latitud: '', longitud: '', estado_activo: true });
      fetchPharmacies();
    } catch (error) {
      alert("Error al registrar la farmacia");
    }
  };

  const handleToggleStatus = async (farmaciaId: string, currentStatus: boolean) => {
    const action = currentStatus ? 'suspender' : 'reactivar';
    if (!confirm(`¿Estás seguro de que deseas ${action} esta farmacia?`)) return;

    try {
      const farmaciaRef = doc(db, 'farmacias', farmaciaId);
      await updateDoc(farmaciaRef, {
        estado_activo: !currentStatus
      });
      fetchPharmacies();
    } catch (error) {
      alert("Error al actualizar el estado");
    }
  };

  if (loading) return (
    <div className="flex justify-center py-20">
      <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-green-600"></div>
    </div>
  );

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h3 className="text-xl font-bold text-gray-800">Farmacias Registradas</h3>
          <p className="text-sm text-gray-500">Gestión de sucursales y responsables sanitarios.</p>
        </div>
        <button
          onClick={() => setShowModal(true)}
          className="bg-green-600 text-white px-5 py-2.5 rounded-xl font-bold hover:bg-green-700 transition-all shadow-lg shadow-green-100 flex items-center gap-2"
        >
          <Plus className="w-5 h-5" />
          Registrar Nueva Farmacia
        </button>
      </div>

      <div className="grid grid-cols-1 gap-4">
        {pharmacies.map((farmacia) => {
          const isActive = farmacia.estado_activo !== false;
          return (
            <div
              key={farmacia.id}
              className={`bg-white p-6 rounded-3xl border transition-all flex items-center justify-between ${
                isActive ? 'border-gray-100 shadow-sm' : 'border-red-100 bg-gray-50 opacity-80'
              }`}
            >
              <div className="flex items-center gap-6">
                <div className={`w-20 h-20 rounded-2xl flex items-center justify-center relative overflow-hidden ${
                  isActive ? 'bg-green-50 text-green-600' : 'bg-gray-200 text-gray-400'
                }`}>
                  {farmacia.foto_fachada_base64 ? (
                    <img src={`data:image/png;base64,${farmacia.foto_fachada_base64}`} alt="Fachada" className="w-full h-full object-cover" />
                  ) : (
                    <Store className="w-10 h-10" />
                  )}
                  {!isActive && (
                    <div className="absolute inset-0 bg-black/40 flex items-center justify-center">
                      <Ban className="text-white w-8 h-8" />
                    </div>
                  )}
                </div>

                <div>
                  <div className="flex items-center gap-3">
                    <h4 className="text-lg font-bold text-gray-800">{farmacia.nombre || 'Sin nombre'}</h4>
                    <span className={`px-2 py-0.5 rounded-lg text-[10px] font-bold uppercase ${
                      isActive ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
                    }`}>
                      {isActive ? 'Activa' : 'Inactiva'}
                    </span>
                  </div>
                  <div className="space-y-1 mt-2">
                    <p className="flex items-center gap-2 text-sm text-gray-500">
                      <MapPin className="w-4 h-4 text-gray-400" /> {farmacia.direccion || 'No especificada'}
                    </p>
                    <p className="flex items-center gap-2 text-sm text-gray-500">
                      <Phone className="w-4 h-4 text-gray-400" /> {farmacia.telefono || 'Sin telf.'}
                    </p>
                  </div>
                </div>
              </div>

              <div className="flex items-center gap-6">
                <div className="bg-white p-3 px-5 rounded-2xl border border-gray-100 flex items-center gap-4 shadow-sm">
                  <div className="w-10 h-10 bg-blue-50 rounded-full flex items-center justify-center text-blue-600 border border-blue-100">
                    <User className="w-5 h-5" />
                  </div>
                  <div>
                    <p className="text-[10px] text-gray-400 font-bold uppercase tracking-wider leading-none mb-1">Responsable</p>
                    <p className="font-bold text-sm text-gray-700">{farmacia.farmaceutico_nombre}</p>
                  </div>
                </div>

                <button
                  onClick={() => handleToggleStatus(farmacia.id, isActive)}
                  className={`flex flex-col items-center justify-center p-3 rounded-2xl transition-all border-2 w-28 group ${
                    isActive
                      ? 'border-red-50 text-red-400 hover:bg-red-50 hover:border-red-100'
                      : 'border-green-50 text-green-500 hover:bg-green-50 hover:border-green-100'
                  }`}
                >
                  {isActive ? <Ban className="w-6 h-6 mb-1" /> : <CheckCircle className="w-6 h-6 mb-1" />}
                  <span className="text-[10px] font-bold uppercase">{isActive ? 'Suspender' : 'Activar'}</span>
                </button>
              </div>
            </div>
          );
        })}
      </div>

      {/* Modal de Registro */}
      {showModal && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-3xl w-full max-w-md overflow-hidden shadow-2xl">
            <div className="p-6 border-b border-gray-100 flex justify-between items-center bg-green-50/50">
              <h4 className="text-xl font-bold text-gray-800">Nueva Farmacia</h4>
              <button onClick={() => setShowModal(false)} className="text-gray-400 hover:text-gray-600"><X /></button>
            </div>
            <form onSubmit={handleCreatePharmacy} className="p-6 space-y-4">
              <div>
                <label className="block text-xs font-bold text-gray-400 uppercase mb-1">Nombre Comercial</label>
                <input
                  type="text" required
                  className="w-full bg-gray-50 border border-gray-100 rounded-xl p-3 focus:ring-2 focus:ring-green-500 outline-none"
                  value={newPharmacy.nombre}
                  onChange={e => setNewPharmacy({...newPharmacy, nombre: e.target.value})}
                />
              </div>
              <div>
                <label className="block text-xs font-bold text-gray-400 uppercase mb-1">Dirección Completa</label>
                <input
                  type="text" required
                  className="w-full bg-gray-50 border border-gray-100 rounded-xl p-3 focus:ring-2 focus:ring-green-500 outline-none"
                  value={newPharmacy.direccion}
                  onChange={e => setNewPharmacy({...newPharmacy, direccion: e.target.value})}
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-gray-400 uppercase mb-1">Teléfono</label>
                  <input
                    type="text"
                    className="w-full bg-gray-50 border border-gray-100 rounded-xl p-3 focus:ring-2 focus:ring-green-500 outline-none"
                    value={newPharmacy.telefono}
                    onChange={e => setNewPharmacy({...newPharmacy, telefono: e.target.value})}
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-gray-400 uppercase mb-1">Estado Inicial</label>
                  <select
                    className="w-full bg-gray-50 border border-gray-100 rounded-xl p-3 focus:ring-2 focus:ring-green-500 outline-none"
                    onChange={e => setNewPharmacy({...newPharmacy, estado_activo: e.target.value === 'true'})}
                  >
                    <option value="true">Activa</option>
                    <option value="false">Inactiva</option>
                  </select>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-gray-400 uppercase mb-1">Latitud</label>
                  <input
                    type="text" placeholder="-16.4..."
                    className="w-full bg-gray-50 border border-gray-100 rounded-xl p-3 focus:ring-2 focus:ring-green-500 outline-none text-xs"
                    value={newPharmacy.latitud}
                    onChange={e => setNewPharmacy({...newPharmacy, latitud: e.target.value})}
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-gray-400 uppercase mb-1">Longitud</label>
                  <input
                    type="text" placeholder="-68.1..."
                    className="w-full bg-gray-50 border border-gray-100 rounded-xl p-3 focus:ring-2 focus:ring-green-500 outline-none text-xs"
                    value={newPharmacy.longitud}
                    onChange={e => setNewPharmacy({...newPharmacy, longitud: e.target.value})}
                  />
                </div>
              </div>
              <button type="submit" className="w-full bg-green-600 text-white py-4 rounded-2xl font-bold hover:bg-green-700 transition-all mt-4 shadow-lg shadow-green-100">
                Guardar Farmacia
              </button>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default Pharmacies;
