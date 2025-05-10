class Genre {
  final int idGenre;
  final String nomGenre;

  Genre({required this.idGenre, required this.nomGenre});

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      idGenre: json['id_genre'] as int,
      nomGenre: json['lib_genre'] == null ? '' : json['lib_genre'] as String,
    );
  }
}