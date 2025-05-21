
import 'package:TicknGo/Screens/interfaces/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/custom_button.dart';
import '../login/inscription_centre_screen.dart';
import '../login/inscription_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtenir les dimensions de l'écran
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      // Utiliser un Container qui prend toute la hauteur disponible comme enfant de AppBackground
      body: AppBackground(
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                // Ajouter une hauteur minimale pour s'assurer que le contenu occupe tout l'écran
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Titre avec effet de profondeur
                      Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Transform.translate(
                          offset: Offset(0, -10),
                          child: Text(
                            'TicknGo',
                            style: GoogleFonts.montserrat(
                              fontSize: screenSize.width * 0.1,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      // Carte décorative
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(horizontal: 10),
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "Bienvenue sur TicknGo",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            SizedBox(height: 15),
                            Text(
                              "Votre compagnon ultime pour un accès rapide et sécurisé aux événements.\n\n"
                                  "Choisissez votre type de compte pour commencer !",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            )
                          ],
                        ),
                      ),

                      SizedBox(height: 30),

                      // Illustration animée avec taille adaptative
                      AnimatedContainer(
                        duration: Duration(seconds: 1),
                        curve: Curves.easeInOut,
                        height: screenSize.height * 0.2,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Effet de halo
                            Container(
                              width: screenSize.width * 0.4,
                              height: screenSize.width * 0.4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.amber.withOpacity(0.3),
                                    Colors.transparent,
                                  ],
                                  stops: [0.1, 0.9],
                                ),
                              ),
                            ),
                            // Image principale
                            Image.asset(
                              'Assets/imgs/Acceuil.png',
                              height: screenSize.height * 0.18,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 40),

                      // Section des boutons d'inscription
                      Container(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Titre de la section
                            Text(
                              "Je souhaite m'inscrire en tant que :",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            SizedBox(height: 20),

                            // Bouton pour les utilisateurs simples
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: screenSize.width * 0.8,
                              ),
                              child: CustomButton(
                                text: "Clients",
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RegistrationScreen1(),
                                    ),
                                  );
                                },
                                buttonColor: Colors.white,
                                textColor: Colors.black,
                                elevation: 8,
                                borderRadius: 15,
                                textStyle: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),

                            SizedBox(height: 15),

                            // Bouton pour les centres
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: screenSize.width * 0.8,
                              ),
                              child: CustomButton(
                                text: " Centres ",
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RegistrationScreen(),
                                    ),
                                  );
                                },
                                buttonColor: Colors.white70,
                                textColor: Colors.black,
                                elevation: 8,
                                borderRadius: 15,
                                textStyle: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 30),

                      // Note informative en bas
                      Text(
                        "Vous pouvez changer de type de compte ultérieurement",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}