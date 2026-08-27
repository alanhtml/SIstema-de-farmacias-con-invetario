class MedicamentoModel {
  final int? id;
  final String nombre;
  final String? principioActivo;
  final String? descripcion;
  final String? laboratorio;
  final String codigoBarras;
  final String? registroSanitario;

  MedicamentoModel({
    this.id,
    required this.nombre,
    this.principioActivo,
    this.descripcion,
    this.laboratorio,
    required this.codigoBarras,
    this.registroSanitario,
  });

  factory MedicamentoModel.fromJson(Map<String, dynamic> json) {
    return MedicamentoModel(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      principioActivo: json['principio_activo'],
      descripcion: json['descripcion'],
      laboratorio: json['laboratorio'],
      codigoBarras: json['codigo_barras'] ?? '',
      registroSanitario: json['registro_sanitario'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'principio_activo': principioActivo,
      'descripcion': descripcion,
      'laboratorio': laboratorio,
      'codigo_barras': codigoBarras,
      'registro_sanitario': registroSanitario,
    };
  }
}

