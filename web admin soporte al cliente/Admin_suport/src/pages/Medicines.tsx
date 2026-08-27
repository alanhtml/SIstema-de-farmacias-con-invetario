import React, { useEffect, useState } from 'react';
import { db } from '../firebase/config';
import { collection, getDocs, addDoc, updateDoc, doc, serverTimestamp } from 'firebase/firestore';
import { Pill, Barcode, Plus, Search, Factory, Edit2, X, Tag, Package } from 'lucide-react';

const Medicines: React.FC = () => {
  const [medicines, setMedicines] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');

  const [formData, setFormData] = useState({
    nombre: '',
    principio_activo: '',
    gtin: '',
    presentacion: '',
    laboratorio: '',
    categoria: 'General'
  });

  useEffect(() => {
    fetchMedicines();
  }, []);

  const fetchMedicines = async () => {
    setLoading(true);
    try {
      const querySnapshot = await getDocs(collection(db, 'medicamentos_maestros'));
      const data = querySnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setMedicines(data);
    } catch (error) {
      console.error("Error fetching medicines:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleOpenModal = (med?: any) => {
    if (med) {
      setEditingId(med.id);
      setFormData({
        nombre: med.nombre || '',
        principio_activo: med.principio_activo || '',
        gtin: med.gtin || '',
        presentacion: med.presentacion || '',
        laboratorio: med.laboratorio || '',
        categoria: med.categoria || 'General'
      });
    } else {
      setEditingId(null);
      setFormData({
        nombre: '',
        principio_activo: '',
        gtin: '',
        presentacion: '',
        laboratorio: '',
        categoria: 'General'
      });
    }
    setShowModal(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      if (editingId) {
        const docRef = doc(db, 'medicamentos_maestros', editingId);
        await updateDoc(docRef, {
          ...formData,
          updatedAt: serverTimestamp()
        });
      } else {
        await addDoc(collection(db, 'medicamentos_maestros'), {
          ...formData,
          createdAt: serverTimestamp()
        });
      }
      setShowModal(false);
      fetchMedicines();
    } catch (error) {
      alert("Error al guardar medicamento");
    }
  };

  const filteredMedicines = medicines.filter(m =>
    m.nombre?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    m.gtin?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    m.principio_activo?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h3 className="text-xl font-bold">Catálogo Maestro</h3>
          <p className="text-sm text-gray-500">Gestión global de medicamentos para toda la red.</p>
        </div>
        <button
          onClick={() => handleOpenModal()}
          className="bg-green-600 text-white px-4 py-2 rounded-lg font-medium hover:bg-green-700 transition-colors flex items-center gap-2 shadow-lg shadow-green-100"
        >
          <Plus className="w-5 h-5" /> Nuevo Medicamento
        </button>
      </div>

      <div className="relative">
        <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 w-5 h-5" />
        <input
          type="text"
          placeholder="Buscar por nombre, GTIN o principio activo..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="w-full pl-12 pr-4 py-3 bg-white border border-gray-200 rounded-xl focus:ring-2 focus:ring-green-500 outline-none transition-all shadow-sm"
        />
      </div>

      {loading ? (
        <div className="flex justify-center py-20">
          <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-green-600"></div>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredMedicines.map((med) => (
            <div key={med.id} className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm hover:shadow-md hover:border-green-200 transition-all relative group">
              <button
                onClick={() => handleOpenModal(med)}
                className="absolute top-4 right-4 p-2 bg-gray-50 text-gray-400 hover:text-green-600 hover:bg-green-50 rounded-lg transition-all opacity-0 group-hover:opacity-100 shadow-sm"
              >
                <Edit2 className="w-4 h-4" />
              </button>

              <div className="flex justify-between items-start mb-4">
                <div className="w-12 h-12 bg-green-50 rounded-xl flex items-center justify-center text-green-600">
                  <Pill className="w-6 h-6" />
                </div>
                <span className="text-[10px] font-bold bg-green-100 text-green-700 px-2 py-1 rounded-lg uppercase tracking-wider">
                  {med.categoria}
                </span>
              </div>

              <h4 className="font-bold text-lg text-gray-800">{med.nombre}</h4>
              <p className="text-sm text-gray-400 mb-4 italic line-clamp-1">{med.principio_activo || 'Sin principio activo'}</p>

              <div className="space-y-2 border-t border-gray-50 pt-4">
                <div className="flex items-center gap-2 text-xs text-gray-500">
                  <Barcode className="w-4 h-4 text-gray-400" />
                  <span className="font-mono">GTIN: {med.gtin || '---'}</span>
                </div>
                <div className="flex items-center gap-2 text-xs text-gray-500">
                  <Package className="w-4 h-4 text-gray-400" />
                  <span>{med.presentacion || 'Unidad'}</span>
                </div>
                <div className="flex items-center gap-2 text-xs text-gray-500">
                  <Factory className="w-4 h-4 text-gray-400" />
                  <span>{med.laboratorio || 'No definido'}</span>
                </div>
              </div>
            </div>
          ))}
          {filteredMedicines.length === 0 && (
            <div className="col-span-full text-center py-20 text-gray-400">
              No se encontraron medicamentos.
            </div>
          )}
        </div>
      )}

      {/* Modal de Edición/Creación */}
      {showModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50 backdrop-blur-sm">
          <div className="bg-white rounded-3xl p-8 max-w-lg w-full shadow-2xl animate-in zoom-in duration-200 max-h-[90vh] overflow-y-auto">
            <div className="flex justify-between items-center mb-6">
              <h3 className="text-2xl font-bold text-gray-800">{editingId ? 'Editar Medicamento' : 'Nuevo Medicamento'}</h3>
              <button onClick={() => setShowModal(false)} className="p-2 hover:bg-gray-100 rounded-full transition-colors"><X /></button>
            </div>

            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="space-y-1">
                <label className="text-xs font-bold text-gray-400 uppercase ml-1">Nombre Comercial</label>
                <input
                  value={formData.nombre}
                  onChange={e => setFormData({...formData, nombre: e.target.value})}
                  className="w-full p-3 bg-gray-50 border border-gray-100 rounded-xl focus:ring-2 focus:ring-green-500 outline-none transition-all"
                  placeholder="Ej: Paracetamol 500mg"
                  required
                />
              </div>

              <div className="space-y-1">
                <label className="text-xs font-bold text-gray-400 uppercase ml-1">Principio Activo</label>
                <input
                  value={formData.principio_activo}
                  onChange={e => setFormData({...formData, principio_activo: e.target.value})}
                  className="w-full p-3 bg-gray-50 border border-gray-100 rounded-xl focus:ring-2 focus:ring-green-500 outline-none"
                  placeholder="Ej: Acetaminofén"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1">
                  <label className="text-xs font-bold text-gray-400 uppercase ml-1">Código GTIN</label>
                  <input
                    value={formData.gtin}
                    onChange={e => setFormData({...formData, gtin: e.target.value})}
                    className="w-full p-3 bg-gray-50 border border-gray-100 rounded-xl focus:ring-2 focus:ring-green-500 outline-none font-mono"
                    placeholder="750123456789"
                    required
                  />
                </div>
                <div className="space-y-1">
                  <label className="text-xs font-bold text-gray-400 uppercase ml-1">Categoría</label>
                  <select
                    value={formData.categoria}
                    onChange={e => setFormData({...formData, categoria: e.target.value})}
                    className="w-full p-3 bg-gray-50 border border-gray-100 rounded-xl focus:ring-2 focus:ring-green-500 outline-none"
                  >
                    <option value="General">General</option>
                    <option value="Analgésicos">Analgésicos</option>
                    <option value="Antibióticos">Antibióticos</option>
                    <option value="Vitaminas">Vitaminas</option>
                    <option value="Infantil">Infantil</option>
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1">
                  <label className="text-xs font-bold text-gray-400 uppercase ml-1">Presentación</label>
                  <input
                    value={formData.presentacion}
                    onChange={e => setFormData({...formData, presentacion: e.target.value})}
                    className="w-full p-3 bg-gray-50 border border-gray-100 rounded-xl focus:ring-2 focus:ring-green-500 outline-none"
                    placeholder="Caja c/ 20 tabletas"
                  />
                </div>
                <div className="space-y-1">
                  <label className="text-xs font-bold text-gray-400 uppercase ml-1">Laboratorio</label>
                  <input
                    value={formData.laboratorio}
                    onChange={e => setFormData({...formData, laboratorio: e.target.value})}
                    className="w-full p-3 bg-gray-50 border border-gray-100 rounded-xl focus:ring-2 focus:ring-green-500 outline-none"
                    placeholder="Ej: Bayer"
                  />
                </div>
              </div>

              <div className="flex gap-4 mt-6">
                <button
                  type="button"
                  onClick={() => setShowModal(false)}
                  className="flex-1 py-3 bg-gray-100 text-gray-600 rounded-xl font-bold hover:bg-gray-200 transition-all"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  className="flex-1 py-3 bg-green-600 text-white rounded-xl font-bold hover:bg-green-700 transition-all shadow-lg shadow-green-100 flex items-center justify-center gap-2"
                >
                  {editingId ? 'Guardar Cambios' : 'Registrar Medicamento'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default Medicines;
