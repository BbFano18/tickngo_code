import 'dart:async';
import 'dart:math' as math;
import 'package:TicknGo/Screens/interfaces/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'acceuil_screen.dart';


// Widget réutilisable pour le fond
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6A3093), // Violet plus foncé
            Color(0xFFA044FF), // Violet plus clair
          ],
        ),
      ),
      child: Stack(
        children: [
          // Éléments décoratifs en arrière-plan
          ...buildBackgroundElements(context),

          // Contenu principal
          child,
        ],
      ),
    );
  }

  List<Widget> buildBackgroundElements(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final random = math.Random(42); // Seed fixe pour générer toujours les mêmes positions

    return [
      // Cercles décoratifs
      Positioned(
        top: -50,
        left: -30,
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
        ),
      ),
      Positioned(
        bottom: -80,
        right: -40,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
        ),
      ),

      // Éléments supplémentaires pour un design plus dynamique
      Positioned(
        top: 120,
        right: 40,
        child: CustomPaint(
          size: Size(60, 60),
          painter: TrianglePainter(Colors.white.withOpacity(0.15)),
        ),
      ),
      Positioned(
        bottom: 150,
        left: 30,
        child: CustomPaint(
          size: Size(40, 40),
          painter: StarPainter(Colors.amber.withOpacity(0.2)),
        ),
      ),

      // Petites étoiles décoratives
      ...List.generate(8, (index) {
        return Positioned(
          top: random.nextDouble() * screenSize.height,
          left: random.nextDouble() * screenSize.width,
          child: Container(
            width: 4 + random.nextDouble() * 6,
            height: 4 + random.nextDouble() * 6,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3 + random.nextDouble() * 0.4),
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    ];
  }
}

// Peintre personnalisé pour le triangle
class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width/2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Peintre personnalisé pour l'étoile
class StarPainter extends CustomPainter {
  final Color color;

  StarPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 2;
    final innerRadius = radius * 0.4;

    // Dessiner une étoile à 5 branches
    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 2 * math.pi / 5) - math.pi / 2;
      final innerAngle = outerAngle + math.pi / 5;

      if (i == 0) {
        path.moveTo(
            centerX + radius * math.cos(outerAngle),
            centerY + radius * math.sin(outerAngle)
        );
      } else {
        path.lineTo(
            centerX + radius * math.cos(outerAngle),
            centerY + radius * math.sin(outerAngle)
        );
      }

      path.lineTo(
          centerX + innerRadius * math.cos(innerAngle),
          centerY + innerRadius * math.sin(innerAngle)
      );
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotateController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    // Contrôleur pour l'animation d'échelle
    _scaleController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Contrôleur pour l'animation de rotation
    _rotateController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 10),
    )..repeat();

    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_rotateController);

    // Démarrer la navigation après 3 secondes
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(Duration(seconds: 3));

    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;

    if (!mounted) return;

    if (isFirstTime) {
      await prefs.setBool('isFirstTime', false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WelcomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AppBackground(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animation de l'icône avec échelle et rotation
                buildAnimatedLogo(),

                SizedBox(height: 40),

                // Titre de l'application
                Text(
                  "TicknGo",
                  style: GoogleFonts.montserrat(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 2.0,
                    shadows: [
                      Shadow(
                        color: Colors.black38,
                        blurRadius: 15,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 15),

                // Nouveau slogan
                Text(
                  "Votre passeport pour le divertissement",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),

                SizedBox(height: 50),

                // Indicateur de chargement amélioré
                Container(
                  width: 180,
                  child: LinearProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                    backgroundColor: Colors.white24,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                SizedBox(height: 25),

                Text(
                  "Préparation de votre expérience...",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _rotateAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (_scaleAnimation.value * 0.2),
          child: Transform.rotate(
            angle: _rotateAnimation.value,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Cercle externe
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.6),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),

                  // Icône de ticket
                  Icon(
                    Icons.confirmation_number_outlined,
                    size: 50,
                    color: Colors.white,
                  ),

                  // Éléments de décoration autour du ticket
                  ...List.generate(4, (index) {
                    return Transform.rotate(
                      angle: (index * math.pi / 2) - (_rotateAnimation.value * 0.5),
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: 70,
                        ),
                        child: Icon(
                          Icons.star,
                          size: 20,
                          color: Colors.amber.withOpacity(0.8),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Exemple d'utilisation du fond réutilisable dans une autre page
class ExamplePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Exemple"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true, // Pour que l'AppBar soit transparente sur le fond
      body: AppBackground(
        child: Center(
          child: Card(
            color: Colors.white.withOpacity(0.9),
            margin: EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Contenu de la page",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6A3093),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Cette page utilise le même fond que le SplashScreen",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
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
}