class Format {
  final int idFormat;
  final String nomFormat;

  Format({required this.idFormat, required this.nomFormat});

  factory Format.fromJson(Map<String, dynamic> json) {
    return Format(
      idFormat: json['id_format'] as int,
      nomFormat: json['lib_format'] == null ? '' : json['lib_format'] as String,
    );
  }
}