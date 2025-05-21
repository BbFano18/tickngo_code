import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../Services/incription_service.dart';
import '../../themes/app_theme.dart';
import '../interfaces/acceuil_screen.dart';
import '../interfaces/splash_screen.dart';

class RegistrationScreen1 extends StatefulWidget {
  const RegistrationScreen1({super.key});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen1> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController(text: '01');
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _password_confirmationController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirm_passwordVisible = false;
  bool _isLoading = false; // Pour gérer l'état de chargement

  // Instance du service API
  final ApiService2 _apiService = ApiService2();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Inscription",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 20)),
      ),
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFormCard(),
                    SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Material(
      borderRadius: BorderRadius.circular(20),
      color: Colors.white.withOpacity(0.15),
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                "Créez votre compte",
                textAlign: TextAlign.start,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
              SizedBox(height: 25),
              _buildNameField(),
              SizedBox(height: 15),
              _buildPhoneField(),
              SizedBox(height: 15),
              _buildPasswordField(),
              SizedBox(height: 15),
              _buildConfirmPasswordField(),
              SizedBox(height: 25),
              _buildRegisterButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      textAlign: TextAlign.start,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: "Nom complet",
        labelStyle: const TextStyle(color: Colors.black54),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        prefixIcon: const Icon(Icons.person_rounded, color: Colors.black54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        filled: true,
        fillColor: Colors.white,
        errorStyle: const TextStyle(color: Colors.red),
      ),
      validator: (value) =>
      value!.isEmpty ? "Veuillez entrer votre nom" : null,
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
          // drapeau du Bénin
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey, width: 1)),
            ),
            child: Row(
              children: [
                // Drapeau du Bénin
                Container(
                  width: 24,
                  height: 16,
                  margin: const EdgeInsets.only(right: 8),
                  child: Row(
                    children: [
                      // Bande verte verticale
                      Expanded(
                        flex: 2, // Occupe environ 2/5 de la largeur
                        child: Container(color: const Color(0xFF008751)),
                      ),
                      // Colonne pour les bandes jaune et rouge horizontales
                      Expanded(
                        flex: 3, // Occupe environ 3/5 de la largeur
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(color: const Color(0xFFFCD116)), // Bande jaune
                            ),
                            Expanded(
                              child: Container(color: const Color(0xFFE8112D)), // Bande rouge
                            ),
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
              controller: _numeroController,
              style: const TextStyle(color: Colors.black87),
              decoration: const InputDecoration(
                labelText: "Numéro de téléphone",
                floatingLabelBehavior: FloatingLabelBehavior.never,
                labelStyle: TextStyle(color: Colors.black54),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: (15)),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, //  uniquement les chiffres
                LengthLimitingTextInputFormatter(10),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  if (newValue.text.length < 2) {
                    return const TextEditingValue(
                      text: "01",
                      selection: TextSelection.collapsed(offset: 2),
                    );
                  }
                  if (newValue.text.length >= 2 && newValue.text.substring(0, 2) != "01") {
                    String updatedText = "01" + newValue.text.substring(2);
                    return TextEditingValue(
                      text: updatedText,
                      selection: TextSelection.collapsed(offset: newValue.selection.end),
                    );
                  }
                  return newValue;
                }),
              ],
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return "Veuillez entrer votre numéro";
                } else if (v.length < 10) {
                  return "Le numéro incorrect";
                }
                return null;
              },
              onChanged: (value) {
                if (value.length < 2 || value.substring(0, 2) != "01") {
                  _numeroController.text = "01" + (value.length > 2 ? value.substring(2) : "");
                  _numeroController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _numeroController.text.length),
                  );
                } else if (value.length > 10) {
                  _numeroController.text = value.substring(0, 10);
                  _numeroController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _numeroController.text.length),
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
      textAlign: TextAlign.start,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: "Mot de passe",
        floatingLabelBehavior: FloatingLabelBehavior.never,
        labelStyle: const TextStyle(color: Colors.black54),
        prefixIcon: const Icon(Icons.lock_rounded, color: Colors.black54),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
            color: Colors.black54,
          ),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        filled: true,
        fillColor: Colors.white,
        errorStyle: const TextStyle(color: Colors.red),
      ),
      validator: (value) => value!.length < 8
          ? "Le mot de passe doit contenir au moins 8 caractères"
          : null,
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _password_confirmationController,
      obscureText: !_isConfirm_passwordVisible,
      textAlign: TextAlign.start,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: "Confirmation mot de passe",
        floatingLabelBehavior: FloatingLabelBehavior.never,
        labelStyle: const TextStyle(color: Colors.black54),
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.black54),
        suffixIcon: IconButton(
          icon: Icon(
            _isConfirm_passwordVisible ? Icons.visibility_off : Icons.visibility,
            color: Colors.black54,
          ),
          onPressed: () => setState(
                  () => _isConfirm_passwordVisible = !_isConfirm_passwordVisible),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        filled: true,
        fillColor: Colors.white,
        errorStyle: const TextStyle(color: Colors.red),
      ),
      validator: (value) => value != _passwordController.text
          ? "Les mots de passe ne correspondent pas"
          : null,
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: _isLoading
          ? Center(child: CircularProgressIndicator( color: Colors.white))
          : ElevatedButton(
        onPressed: _handleRegistration,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 5,
        ),
        child: const Text(
          "S'inscrire",
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Méthode pour gérer l'inscription
  Future<void> _handleRegistration() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _apiService.register(
          name: _nameController.text.trim(),
          numero: _numeroController.text.trim(),
          password: _passwordController.text,
          password_confirmation: _password_confirmationController.text,
        );

        // Si l'inscription réussit, naviguez vers l'écran d'accueil
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        }
      } catch (e) {
        // Afficher une erreur si l'inscription échoue
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur d\'inscription: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numeroController.dispose();
    _passwordController.dispose();
    _password_confirmationController.dispose();
    super.dispose();
  }
}