import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../API/api_config.dart';
import '../../Services/cinema_service.dart';
import 'Canal olympia Marina.dart';
import 'Canal olympia Wologuede.dart';
import '../interfaces/splash_screen.dart';

class CinemaScreen extends StatefulWidget {
  const CinemaScreen({Key? key}) : super(key: key);

  @override
  _CinemaScreenState createState() => _CinemaScreenState();
}

class _CinemaScreenState extends State<CinemaScreen> {
  List<Map<String, dynamic>> cinemas = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCinemas();
  }

  Future<void> _loadCinemas() async {
    try {
      final result = await CinemaService.getCinemas();
      setState(() {
        cinemas = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur de chargement: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAppBar(context),
                const SizedBox(height: 20),
                _buildScreenDescription(),
                const SizedBox(height: 30),
                if (isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  )
                else
                  if (errorMessage != null)
                    Center(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  else
                    _buildCinemaGrid(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        Text(
          "TicknGo",
          style: GoogleFonts.montserrat(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 50),
      ],
    );
  }

  Widget _buildScreenDescription() {
    return Text(
      "Nous vous offrons la possibilité de choisir le cinéma/la salle où vous aimeriez suivre votre film",
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: 16,
        color: Colors.white,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildCinemaGrid(BuildContext context) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
          final imageSize = constraints.maxWidth * 0.35;

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.8,
            ),
            itemCount: cinemas.length,
            itemBuilder: (context, index) {
              return _buildCinemaCard(context, cinemas[index], imageSize);
            },
          );
        },
      ),
    );
  }

  Widget _buildCinemaCard(BuildContext context, Map<String, dynamic> cinemaData, double imageSize) {
    final String name = cinemaData['name'] as String;
    final String? logoUrl = cinemaData['logo'] as String?;
    final int? cinemaId = cinemaData['id_centre'] as int?;

    print('URL du logo pour $name : $logoUrl');

    // Construire l'URL complète seulement si logoUrl existe et n'est pas vide
    final String? fullImageUrl = logoUrl != null && logoUrl.isNotEmpty
        ? (logoUrl.startsWith('http') ? logoUrl : '${ApiConfig.baseUrl}/$logoUrl')
        : null;

    print('URL complète : $fullImageUrl');

    return GestureDetector(
      onTap: () {
        if (cinemaId != null) {
          if (cinemaId == 17) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WologuedeScreen(centreId: 17,)),
            );
          } else if (cinemaId == 16) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MarinaScreen(centreId: 16,)),
            );
          }
        } else {
          print('Ce centre n\'est pas encore disponible : $name');
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: imageSize,
            height: imageSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.2),
                  spreadRadius: 2,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: fullImageUrl != null
                  ? Image.network(
                fullImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, erreur, tracePile) {
                  print('Erreur de chargement de l\'image : $erreur');
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error, color: Colors.red),
                  );
                },
                loadingBuilder: (context, enfant, progressionChargement) {
                  if (progressionChargement == null) return enfant;
                  return Center(
                    child: CircularProgressIndicator(
                      value: progressionChargement.expectedTotalBytes != null
                          ? progressionChargement.cumulativeBytesLoaded /
                          progressionChargement.expectedTotalBytes!
                          : null,
                      color: Colors.white,
                    ),
                  );
                },
              )
                  : Container(
                color: Colors.grey[300],
                child: const Icon(Icons.movie, size: 40, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Flexible(
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}