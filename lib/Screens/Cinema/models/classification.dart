class Classification {
  final int idClassif;
  final String nomClassif;

  Classification({required this.idClassif, required this.nomClassif});

  factory Classification.fromJson(Map<String, dynamic> json) {
    return Classification(
      idClassif: json['id_classif'] as int,
      nomClassif: json['lib_classif']== null ? '' : json['lib_classif'] as String,
    );
  }
}