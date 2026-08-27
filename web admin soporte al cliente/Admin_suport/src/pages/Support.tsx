import React, { useEffect, useState } from 'react';
import { db } from '../firebase/config';
import { collection, getDocs, query, orderBy, updateDoc, doc, arrayUnion, serverTimestamp } from 'firebase/firestore';
import { MessageSquare, AlertCircle, CheckCircle, User, Filter, Send, Image as ImageIcon, Loader2 } from 'lucide-react';

const Support: React.FC = () => {
  const [reports, setReports] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedTab, setSelectedTab] = useState<'todos' | 'pendiente' | 'resuelto'>('todos');
  const [selectedReport, setSelectedReport] = useState<any>(null);
  const [reply, setReply] = useState('');
  const [sending, setSending] = useState(false);

  useEffect(() => {
    fetchReports();
  }, []);

  const fetchReports = async () => {
    try {
      const q = query(collection(db, 'reportes_incidencias'), orderBy('fecha', 'desc'));
      const querySnapshot = await getDocs(q);
      const data = querySnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setReports(data);
      if (selectedReport) {
        const updated = data.find(r => r.id === selectedReport.id);
        if (updated) setSelectedReport(updated);
      }
    } catch (error) {
      console.error("Error fetching reports:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleSendReply = async () => {
    if (!reply.trim() || !selectedReport) return;
    setSending(true);
    try {
      const reportRef = doc(db, 'reportes_incidencias', selectedReport.id);
      await updateDoc(reportRef, {
        respuestas: arrayUnion({
          mensaje: reply,
          remitente: 'Administrador Maestro',
          fecha: new Date().toISOString()
        }),
        estado: 'en proceso'
      });
      setReply('');
      fetchReports();
    } catch (error) {
      alert("Error al enviar respuesta");
    } finally {
      setSending(false);
    }
  };

  const markAsResolved = async (id: string) => {
    try {
      await updateDoc(doc(db, 'reportes_incidencias', id), {
        estado: 'resuelto',
        fecha_resolucion: serverTimestamp()
      });
      fetchReports();
    } catch (error) {
      alert("Error al actualizar reporte");
    }
  };

  const filteredReports = reports.filter(r =>
    selectedTab === 'todos' ? true : (r.estado || 'pendiente') === selectedTab
  );

  if (loading) return <div className="text-center py-10 text-gray-400 font-medium">Conectando al centro de soporte...</div>;

  return (
    <div className="flex h-[calc(100vh-160px)] gap-6">
      {/* Listado de Casos */}
      <div className="w-1/3 bg-white rounded-3xl border border-gray-200 shadow-sm flex flex-col overflow-hidden">
        <div className="p-6 border-b border-gray-100">
          <h3 className="font-bold text-lg mb-4">Bandeja de Entrada</h3>
          <div className="flex bg-gray-50 p-1 rounded-xl border border-gray-100">
            {(['todos', 'pendiente', 'resuelto'] as const).map((tab) => (
              <button
                key={tab}
                onClick={() => setSelectedTab(tab)}
                className={`flex-1 py-2 text-xs font-bold rounded-lg transition-all capitalize ${
                  selectedTab === tab ? 'bg-white text-green-600 shadow-sm' : 'text-gray-400'
                }`}
              >
                {tab}
              </button>
            ))}
          </div>
        </div>

        <div className="flex-1 overflow-auto divide-y divide-gray-50">
          {filteredReports.map((report) => (
            <div
              key={report.id}
              onClick={() => setSelectedReport(report)}
              className={`p-5 cursor-pointer transition-all border-l-4 ${
                selectedReport?.id === report.id ? 'bg-green-50/50 border-green-500' : 'border-transparent hover:bg-gray-50'
              }`}
            >
              <div className="flex justify-between items-start mb-1">
                <span className="text-[10px] font-extrabold text-green-600 bg-green-50 px-2 py-0.5 rounded">
                  {report.nombre_farmaco || 'CONSULTA'}
                </span>
                <span className="text-[10px] text-gray-400">
                  {report.fecha?.toDate ? report.fecha.toDate().toLocaleDateString() : 'Hoy'}
                </span>
              </div>
              <p className="text-sm font-bold text-gray-800 line-clamp-1">{report.descripcion}</p>
              <div className="flex items-center gap-2 mt-2">
                <div className={`w-2 h-2 rounded-full ${report.estado === 'resuelto' ? 'bg-green-500' : 'bg-orange-400 animate-pulse'}`}></div>
                <span className="text-[10px] font-bold text-gray-400 uppercase">{report.estado || 'pendiente'}</span>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Detalle y Chat */}
      <div className="flex-1 bg-white rounded-3xl border border-gray-200 shadow-sm flex flex-col overflow-hidden">
        {selectedReport ? (
          <>
            <div className="p-6 border-b border-gray-100 flex justify-between items-center bg-gray-50/30">
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 bg-green-100 rounded-2xl flex items-center justify-center text-green-600 font-bold">
                  <User />
                </div>
                <div>
                  <h4 className="font-bold text-gray-800">Usuario: {selectedReport.usuario_id?.substring(0, 8)}</h4>
                  <p className="text-xs text-gray-400">ID Reporte: {selectedReport.id}</p>
                </div>
              </div>
              {selectedReport.estado !== 'resuelto' && (
                <button
                  onClick={() => markAsResolved(selectedReport.id)}
                  className="bg-green-600 text-white px-4 py-2 rounded-xl text-sm font-bold hover:bg-green-700 shadow-lg shadow-green-100 flex items-center gap-2"
                >
                  <CheckCircle className="w-4 h-4" /> Marcar Resuelto
                </button>
              )}
            </div>

            <div className="flex-1 overflow-auto p-6 space-y-6">
              {/* Mensaje Original del Usuario */}
              <div className="bg-gray-50 p-5 rounded-2xl border border-gray-100 max-w-2xl">
                <p className="text-xs font-bold text-gray-400 uppercase mb-2">Problema Reportado</p>
                <p className="text-gray-700 font-medium">{selectedReport.descripcion}</p>
                {selectedReport.evidencia_url && (
                  <img src={selectedReport.evidencia_url} className="mt-4 rounded-xl border-4 border-white shadow-sm max-h-60" alt="Evidencia" />
                )}
              </div>

              {/* Historial de Respuestas */}
              {selectedReport.respuestas?.map((res: any, idx: number) => (
                <div key={idx} className="flex justify-end">
                  <div className="bg-green-600 text-white p-4 rounded-2xl rounded-tr-none max-w-md shadow-md">
                    <p className="text-sm font-medium">{res.mensaje}</p>
                    <p className="text-[10px] opacity-70 mt-2 text-right">{new Date(res.fecha).toLocaleString()}</p>
                  </div>
                </div>
              ))}
            </div>

            <div className="p-6 border-t border-gray-100 bg-white">
              <div className="flex gap-4 items-center bg-gray-50 p-2 pl-4 rounded-2xl border border-gray-200 focus-within:ring-2 focus-within:ring-green-500 transition-all">
                <input
                  type="text"
                  value={reply}
                  onChange={(e) => setReply(e.target.value)}
                  onKeyPress={(e) => e.key === 'Enter' && handleSendReply()}
                  placeholder="Escribe la respuesta oficial..."
                  className="flex-1 bg-transparent py-2 text-sm outline-none font-medium text-gray-700"
                />
                <button
                  onClick={handleSendReply}
                  disabled={sending || !reply.trim()}
                  className="bg-green-600 text-white p-2.5 rounded-xl hover:bg-green-700 disabled:bg-gray-300 transition-all"
                >
                  {sending ? <Loader2 className="w-5 h-5 animate-spin" /> : <Send className="w-5 h-5" />}
                </button>
              </div>
            </div>
          </>
        ) : (
          <div className="flex-1 flex flex-col items-center justify-center p-12 text-center text-gray-400">
            <MessageSquare className="w-16 h-16 mb-4 opacity-20" />
            <h3 className="text-xl font-bold text-gray-300">Selecciona un reporte para atender</h3>
          </div>
        )}
      </div>
    </div>
  );
};

export default Support;
