import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:TicknGo/Screens/interfaces/reservation_screen.dart';
import '../../API/api_config.dart';
import '../interfaces/splash_screen.dart';

//Modèle pour un jeu
class Game {
  final String title;
  final String location;
  final String duration;
  final String tariff;
  final String logoUrl;
  final String ageMin;
  final String? programme;

  Game({
    required this.title,
    required this.location,
    required this.duration,
    required this.tariff,
    required this.logoUrl,
    required this.ageMin,
    required this.programme,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    // Extraire le chemin de l'image sans modification
    String logoPath = json['logo_jeux'] as String? ?? '';

    return Game(
      title: json['nom_jeux'] as String? ?? '',
      location: json['lieu_jeux'] as String? ?? '',
      duration: json['duree_jeux'] as String? ?? '',
      tariff: json['tarif'] as String? ?? '',
      logoUrl: logoPath,
      ageMin: json['age_mini'] as String? ?? '',
      programme: json['programme'] as String?,
    );
  }

  // Méthode pour obtenir l'URL complète de l'image
  String getFullLogoUrl() {
    if (logoUrl.isEmpty) return '';
    if (logoUrl.startsWith('http')) return logoUrl;
    // Sinon, on la préfixe avec la base URL appropriée
    return '${ApiConfig.baseUrl2}storage/$logoUrl';
  }
}

class GameService {
  // Récupère la liste des jeux
  Future<List<Map<String, dynamic>>> fetchGames() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl + ApiConfig.gamePath}'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // Extract the 'data' field which contains the array of games
      final List<dynamic> gamesData = responseData['data'];

      return gamesData.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Échec du chargement des jeux (${response.statusCode})');
    }
  }
}

class GamesScreen extends StatefulWidget {
  @override
  _GamesScreenState createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Game>> _futureGames;
  List<Game> _filteredGames = [];

  @override
  void initState() {
    super.initState();
    _futureGames = GameService().fetchGames().then((list) =>
        list.map((json) => Game.fromJson(json)).toList());
    _searchController.addListener(_filterGames);
  }

  void _filterGames() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredGames = _filteredGames
          .where((game) => game.title.toLowerCase().contains(query))
          .toList();
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
              "TicknGo",
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
              padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 25),
                    child: Text(
                      'Jeux Disponibles',
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // Barre de recherche
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
                        hintText: 'Rechercher un jeu...',
                        hintStyle: GoogleFonts.montserrat(),
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
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  // Liste des jeux
                  Expanded(
                    child: FutureBuilder<List<Game>>(
                      future: _futureGames,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Erreur : ${snapshot.error}'));
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('Aucun jeu disponible'));
                        }

                        // Initialisation ou filtre
                        if (_searchController.text.isEmpty) {
                          _filteredGames = snapshot.data!;
                        }

                        return GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            mainAxisExtent: 300,
                          ),
                          itemCount: _filteredGames.length,
                          itemBuilder: (context, index) =>
                              _buildGameCard(context, _filteredGames[index]),
                        );
                      },
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

  Widget _buildGameCard(BuildContext context, Game game) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
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
                child: game.getFullLogoUrl().isNotEmpty
                    ? Image.network(
                  game.getFullLogoUrl(),
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, trace) {
                    print("Erreur de chargement d'image: $err pour ${game.getFullLogoUrl()}");
                    return const Icon(Icons.broken_image, color: Colors.white, size: 60);
                  },
                )
                    : Container(
                  color: Colors.grey.withOpacity(0.3),
                  width: double.infinity,
                  child: const Icon(Icons.videogame_asset, color: Colors.white70, size: 60),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(Icons.access_time, game.duration),
                    _buildDetailRow(Icons.location_on, game.location),
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
                              builder: (context) => GameDetailsScreen(game: game),
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

class GameDetailsScreen extends StatelessWidget {
  final Game game;

  const GameDetailsScreen({super.key, required this.game});

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
              game.title, // Afficher le titre du jeu dans l'appbar
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
                    child: game.getFullLogoUrl().isNotEmpty
                        ? Image.network(
                      game.getFullLogoUrl(),
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, trace) {
                        print("Erreur de chargement d'image dans détail: $err pour ${game.getFullLogoUrl()}");
                        return const Icon(Icons.broken_image, color: Colors.white, size: 80);
                      },
                    )
                        : Container(
                      height: 250,
                      width: double.infinity,
                      color: Colors.grey.withOpacity(0.3),
                      child: const Icon(Icons.videogame_asset, color: Colors.white70, size: 80),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    game.title,
                    style: GoogleFonts.montserrat(
                      fontSize: 26,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildDetailItem(Icons.access_time, "Durée", game.duration),
                  _buildDetailItem(Icons.location_on, "Lieu", game.location),
                  _buildDetailItem(Icons.euro, "Tarif", "${game.tariff} FCFA"),
                  _buildDetailItem(Icons.cake, "Âge minimum", game.ageMin),
                  if (game.programme != null && game.programme!.isNotEmpty)
                    _buildDetailItem(Icons.event, "Programme", game.programme!),
                  const SizedBox(height: 25),
                  Text(
                    "Description du jeu",
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Ce jeu vous plonge dans une expérience immersive avec des graphismes incroyables et un gameplay captivant. Venez profiter de ce moment unique !",
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: Colors.grey[300],
                      height: 1.5,
                    ),
                  ),
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
                                  eventTitle: game.title,
                                  eventDate: "Aujourd'hui",  // You might want to add a proper date field to Game class
                                  eventTime: game.duration,
                                  eventLocation: game.location,
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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.white),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$label :",
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
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
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