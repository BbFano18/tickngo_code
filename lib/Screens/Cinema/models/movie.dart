class Movie {
  final int idFilm;
  final String nomFilm;
  final String? image;
  final String dureeFilm;
  final int? idCatFil;
  final int? idGenre;
  final int? idFormat;
  final int? idLangue;
  final int? idClassif;

  // Nouveaux champs pour les libellés
  String? categorie;
  String? genre;
  String? format;
  String? langue;
  String? classification;

  Movie({
    required this.idFilm,
    required this.nomFilm,
    this.image,
    required this.dureeFilm,
    this.idCatFil,
    this.idGenre,
    this.idFormat,
    this.idLangue,
    this.idClassif,
    this.categorie,
    this.genre,
    this.format,
    this.langue,
    this.classification,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      idFilm: json['id_film'] as int,
      nomFilm: json['nom_film'] == null ? '' : json['nom_film'] as String,
      image: json['image'] == null ? null : json['image'] as String?,
      dureeFilm: json['duree_film'] == null ? '' : json['duree_film'] as String,
      idCatFil: json['id_cat_fil'] as int?,
      idGenre: json['id_genre'] as int?,
      idFormat: json['id_format'] as int?,
      idLangue: json['id_langue'] as int?,
      idClassif: json['id_classif'] as int?,
    );
  }

}