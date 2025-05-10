class Language {
  final int idLangue;
  final String nomLangue;

  Language({required this.idLangue, required this.nomLangue});

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      idLangue: json['id_langue'] as int,
      nomLangue: json['lib_langue']== null ? '' : json['lib_langue'] as String,
    );
  }
}