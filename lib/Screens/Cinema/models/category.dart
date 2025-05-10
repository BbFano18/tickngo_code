class Category {
  final int idCatFil;
  final String nomCatFil;

  Category({required this.idCatFil, required this.nomCatFil});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      idCatFil: json['id_cat_fil'] as int,
      nomCatFil: json['lib_cat_fil'] == null ? '' : json['lib_cat_fil'] as String,
    );
  }
}