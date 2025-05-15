import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../API/api_config.dart';
import '../interfaces/reservation_screen.dart';
import '../interfaces/splash_screen.dart';
import 'models/movie.dart';

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
                  if (movie.classification != null) _buildDetailItem(Icons.warning, 'Classification', movie.classification!),
                  const SizedBox(height: 20),
                  Text(
                    'Tarifs',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildDetailItem(Icons.child_care, 'Tarif Enfant', '${movie.tarifEnfantFilm ?? 0} FCFA'),
                  _buildDetailItem(Icons.person, 'Tarif Adulte', '${movie.tarifAdulteFilm ?? 0} FCFA'),
                  _buildDetailItem(Icons.star, 'Tarif Première', '${movie.tarifPremiere ?? 0} FCFA'),
                  const SizedBox(height: 20),
                  // Nouveau bouton ajouté ici
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
                                  eventTime: "",
                                  eventLocation: "",
                                  ticketPrices: {
                                    "Adulte": 2000,
                                    "Enfant": 1000,
                                  },
                                  categoryPrices: {
                                    "Standard": 0,
                                    "VIP": 500,
                                  },
                                  type: ReservationType.film,
                                  duration: movie.dureeFilm,
                                  classification: movie.classification,
                                  centreName: "Canal Olympia",
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