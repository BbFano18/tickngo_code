import 'dart:convert';

import 'package:TicknGo/Screens/login/inscription_centre_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../Services/connexion_centre_service.dart';
import '../../themes/app_theme.dart';
import '../Dashbord/Pages/accueil_screen.dart';
import '../interfaces/splash_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phoneController =
  TextEditingController(text: "01");
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isSplashVisible = true;

  final AuthService _authService = AuthService();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    setState(() => _isLoading = true);

    // 1. Petite attente pour le splash
    await Future.delayed(const Duration(seconds: 1));

    // 2. Vérifie si la session est toujours valide (<= 24 h)
    bool isLoggedIn = await _authService.isLoggedIn();

    if (isLoggedIn) {
      // Redirection automatique vers le dashboard
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => DashboardScreen()),
        );
      }
    } else {
      // Affiche l'écran de login
      setState(() {
        _isSplashVisible = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (kDebugMode) {
      print("Numéro de téléphone : ${_phoneController.text}");
      print("Mot de passe : ${_passwordController.text}");
    }

    final result = await _authService.login(
      _phoneController.text,
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      // La session (token + timestamp) est déjà stockée par AuthService
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => DashboardScreen()),
              (route) => false,
        );
      }
    } else {
      setState(() => _errorMessage = result['message']);
    }
  }

  Widget _buildFormCard() {
    return Material(
      borderRadius: BorderRadius.circular(20),
      color: const Color.fromRGBO(255, 255, 255, 0.15),
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 25),
              _buildPhoneField(),
              const SizedBox(height: 20),
              _buildPasswordField(),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ],
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 10,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.45,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        "Mot de passe oublié ?",
                        style: GoogleFonts.poppins(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.45,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => RegistrationScreen()),
                        );
                      },
                      child: Text(
                        "S'inscrire",
                        style: GoogleFonts.poppins(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _buildLoginButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 4,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
          "SE CONNECTER",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey),
      ),
      child: Row(
        children: [
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                  right:
                  BorderSide(color: Colors.grey, width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 16,
                  margin: const EdgeInsets.only(right: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child:
                        Container(color: const Color(0xFF008751)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            Expanded(
                                child: Container(
                                    color: const Color(0xFFFCD116))),
                            Expanded(
                                child: Container(
                                    color: const Color(0xFFE8112D))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Text(
                  "+229",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TextFormField(
              keyboardType: TextInputType.phone,
              controller: _phoneController,
              style: const TextStyle(color: Colors.black87),
              decoration: const InputDecoration(
                labelText: "Numéro de téléphone",
                floatingLabelBehavior:
                FloatingLabelBehavior.never,
                labelStyle: TextStyle(color: Colors.black54),
                prefixIcon:
                Icon(Icons.phone, color: Colors.black54),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 12, vertical: 16),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
                TextInputFormatter.withFunction(
                        (oldValue, newValue) {
                      if (newValue.text.length < 2) {
                        return const TextEditingValue(
                          text: "01",
                          selection:
                          TextSelection.collapsed(offset: 2),
                        );
                      }
                      if (newValue.text.length >= 2 &&
                          newValue.text.substring(0, 2) !=
                              "01") {
                        String updatedText =
                            "01" + newValue.text.substring(2);
                        return TextEditingValue(
                          text: updatedText,
                          selection: TextSelection.collapsed(
                              offset:
                              newValue.selection.end),
                        );
                      }
                      return newValue;
                    }),
              ],
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return "Veuillez entrer votre numéro";
                } else if (v.length < 10) {
                  return "Le numéro est incorrect";
                }
                return null;
              },
              onChanged: (value) {
                if (value.length < 2 ||
                    value.substring(0, 2) != "01") {
                  _phoneController.text =
                      "01" +
                          (value.length > 2
                              ? value.substring(2)
                              : "");
                  _phoneController.selection =
                      TextSelection.fromPosition(
                        TextPosition(
                            offset:
                            _phoneController.text.length),
                      );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: "Mot de passe",
        floatingLabelBehavior:
        FloatingLabelBehavior.never,
        labelStyle: const TextStyle(color: Colors.black54),
        prefixIcon:
        const Icon(Icons.lock_rounded, color: Colors.black54),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible
                ? Icons.visibility_off
                : Icons.visibility,
            color: Colors.black54,
          ),
          onPressed: () => setState(
                  () => _isPasswordVisible = !_isPasswordVisible),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          const BorderSide(color: Colors.grey),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (v) => v!.isEmpty
          ? "Veuillez entrer votre mot de passe"
          : (v.length < 6
          ? "Minimum 6 caractères"
          : null),
    );
  }

  /// Splash screen avec LinearProgressIndicator et slogan
  Widget _buildSplashScreen() {
    return Scaffold(
      body: SafeArea(
        child: AppBackground(
          child: Center(
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
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
                const SizedBox(height: 15),
                Text(
                  "Votre passeport pour le divertissement",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 50),
                Container(
                  width: 180,
                  child: LinearProgressIndicator(
                    valueColor:
                    AlwaysStoppedAnimation<Color>(
                        Colors.amber),
                    backgroundColor: Colors.white24,
                    minHeight: 6,
                    borderRadius:
                    BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isSplashVisible
        ? _buildSplashScreen()
        : Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Connexion",
          style: GoogleFonts.montserrat(
              color: Colors.white,
              fontWeight: FontWeight.w500),
        ),
      ),
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 24),
            child: Center(
              child: SingleChildScrollView(
                physics:
                const BouncingScrollPhysics(),
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    _buildFormCard(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
