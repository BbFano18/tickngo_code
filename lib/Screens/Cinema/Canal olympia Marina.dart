import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../API/api_config.dart';
import '../interfaces/reservation_screen.dart';
import '../interfaces/splash_screen.dart';

// Modèle pour un film
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
      // Ajout des champs imbriqués du JSON directement ici
      categorie: json['categorie_film'] != null ? json['categorie_film']['lib_cat_fil'] as String? : null,
      genre: json['genre'] != null ? json['genre']['lib_genre'] as String? : null,
      format: json['format'] != null ? json['format']['lib_format'] as String? : null,
      langue: json['langue'] != null ? json['langue']['lib_langue'] as String? : null,
      classification: json['classification'] != null ? json['classification']['lib_classif'] as String? : null,
    );
  }
}

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

// Service pour accéder aux films
class MovieService {
  Future<List<Movie>> fetchMovies(int centreId) async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}centre/$centreId/films'));
    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> list = data['data'];
      return list.map((e) => Movie.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Erreur ${response.statusCode}');
    }
  }

  // Les autres méthodes de récupération restent identiques
  Future<Category?> fetchCategory(int? id) async {
    if (id == null) return null;
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}categoriefilm/$id'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Category.fromJson(data['data']);
    } else {
      print('Erreur lors de la récupération de la catégorie $id: ${response.statusCode}');
      return null;
    }
  }

  Future<Genre?> fetchGenre(int? id) async {
    if (id == null) return null;
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}genre/$id'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Genre.fromJson(data['data']);
    } else {
      print('Erreur lors de la récupération du genre $id: ${response.statusCode}');
      return null;
    }
  }

  Future<Format?> fetchFormat(int? id) async {
    if (id == null) return null;
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}format/$id'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Format.fromJson(data['data']);
    } else {
      print('Erreur lors de la récupération du format $id: ${response.statusCode}');
      return null;
    }
  }

  Future<Language?> fetchLanguage(int? id) async {
    if (id == null) return null;
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}langue/$id'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Language.fromJson(data['data']);
    } else {
      print('Erreur lors de la récupération de la langue $id: ${response.statusCode}');
      return null;
    }
  }

  Future<Classification?> fetchClassification(int? id) async {
    if (id == null) return null;
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}classification/$id'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Classification.fromJson(data['data']);
    } else {
      print('Erreur lors de la récupération de la classification $id: ${response.statusCode}');
      return null;
    }
  }
}

// Écran principal affichant la grille de films
class MarinaScreen extends StatefulWidget {
  final int centreId;
  const MarinaScreen({Key? key, required this.centreId}) : super(key: key);

  @override
  State<MarinaScreen> createState() => _MarinaScreenState();
}

class _MarinaScreenState extends State<MarinaScreen>{
  final MovieService _service = MovieService();
  final TextEditingController _searchController = TextEditingController();
  List<Movie> _movies = [];
  List<Movie> _filtered = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMovies();
    _searchController.addListener(_applyFilter);
  }

  Future<void> _loadMovies() async {
    try {
      final list = await _service.fetchMovies(widget.centreId);
      // Récupérer les libellés pour chaque film si nécessaire
      // Cette étape peut ne plus être nécessaire si les données sont déjà incluses dans la réponse JSON
      // comme indiqué dans l'exemple que vous avez fourni
      await Future.wait(list.map((movie) async {
        if (movie.categorie == null) {
          movie.categorie = (await _service.fetchCategory(movie.idCatFil))?.nomCatFil;
        }
        if (movie.genre == null) {
          movie.genre = (await _service.fetchGenre(movie.idGenre))?.nomGenre;
        }
        if (movie.format == null) {
          movie.format = (await _service.fetchFormat(movie.idFormat))?.nomFormat;
        }
        if (movie.langue == null) {
          movie.langue = (await _service.fetchLanguage(movie.idLangue))?.nomLangue;
        }
        if (movie.classification == null) {
          movie.classification = (await _service.fetchClassification(movie.idClassif))?.nomClassif;
        }
      }));
      setState(() {
        _movies = list;
        _filtered = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _movies.where((movie) {
        return movie.nomFilm.toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'TicknGo',
              style: GoogleFonts.montserrat(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Films Disponibles',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // barre de recherche
                  Container(
                    height: 50,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Rechercher un film...',
                        prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                            : null,
                      ),
                      style: GoogleFonts.montserrat(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                  // contenu
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : _error != null
                        ? Center(
                      child: Text('Erreur: $_error', style: const TextStyle(color: Colors.white)),
                    )
                        : GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        mainAxisExtent: 300,
                      ),
                      itemCount: _filtered.length,
                      itemBuilder: (context, idx) => _buildMovieCard(context, _filtered[idx]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMovieCard(BuildContext context, Movie movie) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          color: Colors.black.withOpacity(0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: movie.image != null && movie.image!.isNotEmpty
                    ? Image.network(
                  //image
                  '${ApiConfig.baseUrl2}storage/${movie.image!}',
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, trace) {
                    print("Erreur de chargement d'image: $err pour ${movie.image}");
                    return const Icon(Icons.broken_image, color: Colors.white, size: 60);
                  },
                )
                    : Container(
                  color: Colors.grey.withOpacity(0.3),
                  width: double.infinity,
                  child: const Icon(Icons.movie, color: Colors.white70, size: 60),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.nomFilm,
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(Icons.access_time, movie.dureeFilm),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MovieDetailScreen(movie: movie),
                            ),
                          );
                        },
                        child: Text(
                          'Voir plus',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[300]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: Colors.grey[300],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// Détails du film
class MovieDetailScreen extends StatelessWidget {
  final Movie movie;
  const MovieDetailScreen({Key? key, required this.movie}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              movie.nomFilm,
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: movie.image != null && movie.image!.isNotEmpty
                        ? Image.network(
                      '${ApiConfig.baseUrl2}storage/${movie.image!}',
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, trace) {
                        print("Erreur de chargement d'image dans détail: $err pour ${movie.image}");
                        return const Icon(Icons.broken_image, color: Colors.white, size: 80);
                      },
                    )
                        : Container(
                      height: 250,
                      width: double.infinity,
                      color: Colors.grey.withOpacity(0.3),
                      child: const Icon(Icons.movie, color: Colors.white70, size: 80),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    movie.nomFilm,
                    style: GoogleFonts.montserrat(
                      fontSize: 26,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildDetailItem(Icons.access_time, 'Durée', movie.dureeFilm),
                  if (movie.categorie != null) _buildDetailItem(Icons.category, 'Catégorie', movie.categorie!),
                  if (movie.genre != null) _buildDetailItem(Icons.theaters, 'Genre', movie.genre!),
                  if (movie.format != null) _buildDetailItem(Icons.movie_filter, 'Format', movie.format!),
                  if (movie.langue != null) _buildDetailItem(Icons.language, 'Langue', movie.langue!),
                  if (movie.classification != null) _buildDetailItem(Icons.assignment_ind, 'Classification', movie.classification!),

                  // Nouveau bouton ajouté ici
                  const SizedBox(height: 30),
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReservationScreen(
                                reservation: Reservation(
                                  eventTitle: movie.nomFilm,
                                  eventDate: "",
                                  eventTime: movie.dureeFilm,
                                  eventLocation: "Canal Olympia Marina",
                                  ticketPrices: {
                                    "Adulte": 2000,
                                    "Enfant": 1000,
                                  },
                                  categoryPrices: {
                                    "Standard": 0,
                                    "VIP": 500,
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'Prendre un ticket',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label:',
                  style: GoogleFonts.montserrat(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}