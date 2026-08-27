class Lote {
  final String? id;
  final String medicamentoId;
  final String numeroLote;
  final int cantidadInicial;
  final int cantidadActual;
  final String fechaVencimiento;
  final String? fechaRegistro;
  final String farmaciaId; // Cambiado a String para compatibilidad con Firestore
  final String estado; // RF-17: activo, vencido, retirado, agotado

  Lote({
    this.id,
    required this.medicamentoId,
    required this.numeroLote,
    required this.cantidadInicial,
    required this.cantidadActual,
    required this.fechaVencimiento,
    this.fechaRegistro,
    required this.farmaciaId,
    this.estado = 'activo',
  });

  Map<String, dynamic> toJson() {
    return {
      'medicamento_id': medicamentoId,
      'numero_lote': numeroLote,
      'cantidad_inicial': cantidadInicial,
      'cantidad_actual': cantidadActual,
      'fecha_vencimiento': fechaVencimiento,
      'farmacia_id': farmaciaId,
      'estado': estado,
      if (fechaRegistro != null) 'fecha_registro': fechaRegistro,
    };
  }

  factory Lote.fromJson(Map<String, dynamic> json, {String? docId}) {
    return Lote(
      id: docId ?? json['id']?.toString(),
      medicamentoId: json['medicamento_id']?.toString() ?? '',
      numeroLote: json['numero_lote'] ?? '',
      cantidadInicial: (json['cantidad_inicial'] as num?)?.toInt() ?? 0,
      cantidadActual: (json['cantidad_actual'] as num?)?.toInt() ?? 0,
      fechaVencimiento: json['fecha_vencimiento'] ?? '',
      fechaRegistro: json['fecha_registro']?.toString(),
      farmaciaId: json['farmacia_id']?.toString() ?? '',
      estado: json['estado'] ?? 'activo',
    );
  }
}
