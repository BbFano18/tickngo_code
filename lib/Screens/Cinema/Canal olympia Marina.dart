import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../API/api_config.dart';
import '../../Services/movie_service.dart';
import '../interfaces/splash_screen.dart';
import 'models/movie.dart';
import 'movie_detail_screen.dart';

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
