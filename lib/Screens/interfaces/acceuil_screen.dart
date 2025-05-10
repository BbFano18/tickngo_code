import 'package:TicknGo/Screens/interfaces/splash_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../Services/connexion_centre_service.dart';
import '../login/connexion_centre_screen.dart';
import '../login/inscription_centre_screen.dart';
import '../Dashbord/Pages/accueil_screen.dart';
import '../Cinema/cinema.dart';
import '../Evenement/evenement_screen.dart';
import '../Jeu/jeu_screen.dart';
import 'maintenance_screen.dart';
import 'profil_screen.dart';
import 'tickets_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final CarouselSliderController _carouselController = CarouselSliderController();
  final List<String> imagePaths = [
    'Assets/imgs/pubeven.jpg',
    'Assets/imgs/pubjeux.jpg',
    'Assets/imgs/pubciné.jpeg',
  ];

  final AuthService _authService = AuthService();
  bool _hasAccessedDashboard = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  // Initialise l'état d'accès au dashboard en fonction de l'authentification et du délai de 24h
  Future<void> _initialize() async {
    // Vérifier si l'utilisateur est connecté et si le token est valide
    final loggedIn = await _authService.isLoggedIn();
    final validToken = loggedIn ? await _authService.validateToken() : false;

    if (validToken) {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString('dashboardAccessDate');

      if (timestamp != null) {
        final accessDate = DateTime.parse(timestamp);
        final hoursSince = DateTime.now().difference(accessDate).inHours;
        if (hoursSince < 24) {
          _hasAccessedDashboard = true;
        } else {
          // Réinitialiser après 24h
          await prefs.remove('dashboardAccessDate');
          _hasAccessedDashboard = false;
        }
      } else {
        _hasAccessedDashboard = false;
      }
    } else {
      _hasAccessedDashboard = false;
    }

    setState(() {});
  }

  Future<void> _setDashboardAccessDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dashboardAccessDate', DateTime.now().toIso8601String());
  }

  void _navigateFromImage(int index) {
    final destinations = {
      'cine': CinemaScreen(),
      'even': EventsScreen(),
      'jeu': GamesScreen(),
    };

    for (var key in destinations.keys) {
      if (imagePaths[index].contains(key)) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => destinations[key]!),
        );
        return;
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAppBar(),
                const SizedBox(height: 20),
                _buildImageCarousel(),
                const SizedBox(height: 20),
                _buildPageIndicators(),
                const SizedBox(height: 40),
                _buildSectionTitle(),
                const SizedBox(height: 30),
                _buildCategoryButtons(),
                const SizedBox(height: 50),
                _buildOrganizerSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildAppBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                "TicknGo",
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.symmetric(horizontal: 1.0),
              iconSize: 20,
              icon: const Icon(Icons.person_outline, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.symmetric(horizontal: 1.0),
              iconSize: 20,
              icon: const Icon(Icons.confirmation_number_outlined, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TicketsScreen()),
              ),
            ),
            const SizedBox(width: 4),
            _buildNotificationButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildNotificationButton() {
    const hasUnread = true;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.symmetric(horizontal: 1.0),
          iconSize: 20,
          icon: const Icon(Icons.notifications_none_outlined, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MaintenancePage()),
          ),
        ),
        if (hasUnread)
          const Positioned(
            right: 10,
            top: 10,
            child: Icon(
              Icons.brightness_1,
              size: 12,
              color: Colors.white,
            ),
          )
      ],
    );
  }

  Widget _buildImageCarousel() {
    return GestureDetector(
      onTap: () => _navigateFromImage(_currentIndex),
      child: CarouselSlider(
        carouselController: _carouselController,
        options: CarouselOptions(
          height: 240,
          viewportFraction: 0.85,
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 4),
          autoPlayCurve: Curves.fastOutSlowIn,
          enlargeCenterPage: true,
          enlargeStrategy: CenterPageEnlargeStrategy.height,
          onPageChanged: (index, reason) => setState(() => _currentIndex = index),
        ),
        items: imagePaths.map((path) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                path,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.error, color: Colors.white),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPageIndicators() {
    return AnimatedSmoothIndicator(
      activeIndex: _currentIndex,
      count: imagePaths.length,
      effect: ExpandingDotsEffect(
        activeDotColor: Colors.white,
        dotColor: Colors.white.withOpacity(0.5),
        dotHeight: 8,
        dotWidth: 8,
        spacing: 10,
        expansionFactor: 3,
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Text(
      "Explorez nos options",
      style: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  Widget _buildCategoryButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCategoryItem('Cinéma', 'Assets/imgs/cine.png', CinemaScreen()),
          _buildCategoryItem('Événement', 'Assets/imgs/even.png', EventsScreen()),
          _buildCategoryItem('Jeux', 'Assets/imgs/jeu.png', GamesScreen()),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String label, String imagePath, Widget screen) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(imagePath),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrganizerSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Text(
            "Vous êtes propriétaire d'un centre ?",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "Rejoignez notre communauté pour gérer vos événements",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 20),
          // Affichage conditionnel selon l'état d'authentification
          _hasAccessedDashboard ? _buildDashboardButton() : _buildHorizontalButtons(),
        ],
      ),
    );
  }

  Widget _buildHorizontalButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: _buildAuthButton("Inscription", RegistrationScreen()),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: _buildAuthButton("Connexion", LoginScreen()),
        ),
      ],
    );
  }

  Widget _buildDashboardButton() {
    return ElevatedButton(
      onPressed: () async {
        await _setDashboardAccessDate();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardScreen()),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        minimumSize: const Size(200, 45),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: const Text("Voir le dashboard"),
    );
  }

  Widget _buildAuthButton(String text, Widget screen) {
    return ElevatedButton(
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );

        if (result == 'success') {
          // Après connexion ou inscription réussie, réinitialiser l'état
          await _initialize();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        minimumSize: const Size(100, 45),
        maximumSize: const Size(150, 50),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        textStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(text),
      ),
    );
  }
}