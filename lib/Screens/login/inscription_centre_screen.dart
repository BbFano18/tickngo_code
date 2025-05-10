import 'dart:io';

import 'package:TicknGo/Screens/interfaces/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../Services/inscription_centre_service.dart';
import '../../themes/app_theme.dart';
import '../interfaces/acceuil_screen.dart';
import 'connexion_centre_screen.dart';


class RegistrationScreen extends StatefulWidget {
  RegistrationScreen({super.key});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _mdpController = TextEditingController();
  final TextEditingController _confirmMdpController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _selectedVille;
  PlatformFile? _selectedLogo;
  List<PlatformFile> _selectedDocs = [];
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  List<String> villes = ["Cotonou", "Porto-Novo"];

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _selectedLogo = result.files.first);
    }
  }

  Future<void> _pickDocuments() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _selectedDocs = result.files);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Création de compte",
            style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.w500)),
      ),
      // Utilisation du widget AppBackground importé de splash_screen.dart
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
              _buildInputField(
                controller: _nomController,
                label: "Nom de du centre",
                icon: Icons.business_rounded,
                validator: (v) => v!.isEmpty ? "Ce champ est obligatoire" : null,
              ),
              const SizedBox(height: 15),
              _buildCityDropdown(),
              const SizedBox(height: 15),
              _buildPhoneField(), // Use _buildPhoneField here.
              const SizedBox(height: 15),
              _buildFilePicker(
                label: "Logo (JPG/PNG)",
                onPressed: _pickLogo,
                file: _selectedLogo,
                labelStyle: TextStyle(color: Colors.white),  // Texte du label en blanc
              ),
              const SizedBox(height: 15),
              _buildFilePicker(
                label: "Pièces administratifs (PDF/DOCX)",
                onPressed: _pickDocuments,
                files: _selectedDocs,
                labelStyle: TextStyle(color: Colors.white),  // Texte du label en blanc
              ),
              const SizedBox(height: 15),
              _buildInputField(
                controller: _descriptionController,
                label: "Description",
                icon: Icons.description_rounded,
                maxLines: 3,
                validator: (v) => v!.isEmpty ? "Ce champ est obligatoire" : null,
              ),
              const SizedBox(height: 15),
              _buildPasswordField(),
              const SizedBox(height: 25),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLines,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.black),
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        prefixIcon: Icon(icon, color: Colors.black54),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        filled: true,
        fillColor: Colors.white,
        errorStyle: const TextStyle(color: Colors.red),
      ),
      validator: validator,
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
          // Partie indicatif avec drapeau du Bénin
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey, width: 1)),
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
                        child: Container(color: const Color(0xFF008751)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(color: const Color(0xFFFCD116)),
                            ),
                            Expanded(
                              child: Container(color: const Color(0xFFE8112D)),
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
              controller: _phoneController,
              style: const TextStyle(color: Colors.black87),
              decoration: const InputDecoration(
                labelText: "Numéro de téléphone",
                floatingLabelBehavior: FloatingLabelBehavior.never,
                labelStyle: TextStyle(color: Colors.black54),
                prefixIcon: Icon(Icons.phone, color: Colors.black54),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
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
                  _phoneController.text = "01" + (value.length > 2 ? value.substring(2) : "");
                  _phoneController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _phoneController.text.length),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildCityDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedVille,
      dropdownColor: Colors.white,
      style: const TextStyle(color: Colors.black),
      icon: const Icon(Icons.arrow_drop_down_circle_rounded, color: Colors.black54),
      decoration: InputDecoration(
        labelText: "Ville",
        labelStyle: const TextStyle(color: Colors.black54),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        prefixIcon: const Icon(Icons.location_city_rounded, color: Colors.black54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: villes.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedVille = value),
      validator: (v) => v == null ? "Sélectionnez une ville" : null,
    );
  }
  Widget _buildFilePicker({
    required String label,
    required Function() onPressed,
    PlatformFile? file,
    List<PlatformFile>? files,
    required TextStyle labelStyle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle), // ✅ Correction ici
        const SizedBox(height: 8),
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey),
            ),
            child: Row(
              children: [
                Icon(Icons.upload_rounded, color: Colors.grey[700]),
                const SizedBox(width: 10),
                Expanded(
                  child: files != null
                      ? Text(
                    "${files.length} fichier(s) sélectionné(s)",
                    style: const TextStyle(color: Colors.grey),
                  )
                      : file != null
                      ? Text(
                    file.name,
                    style: const TextStyle(color: Colors.black87),
                  )
                      : Text(
                    "Cliquez pour téléverser",
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildPasswordField() {
    return Column(
      children: [
        // Champ "Mot de passe"
        TextFormField(
          controller: _mdpController,
          obscureText: !_isPasswordVisible,
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
          ),
          onChanged: (_) => setState(() {}),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return "Veuillez saisir un mot de passe";
            }
            if (value.trim().length < 8) {
              return "Minimum 8 caractères";
            }
            return null;
          },
        ),
        const SizedBox(height: 15),
        // Champ "Confirmer le mot de passe"
        TextFormField(
          controller: _confirmMdpController,
          obscureText: !_isConfirmPasswordVisible,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            labelText: "Confirmez le mot de passe",
            floatingLabelBehavior: FloatingLabelBehavior.never,
            labelStyle: const TextStyle(color: Colors.black54),
            prefixIcon: const Icon(Icons.lock_rounded, color: Colors.black54),
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: Colors.black54,
              ),
              onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: (_) => setState(() {}),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return "Veuillez confirmer le mot de passe";
            }
            if (value.trim() != _mdpController.text.trim()) {
              return "Mots de passe non identiques";
            }
            return null;
          },
        ),
      ],
    );
  }
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegistration,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 5,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
          "S'inscrire",
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

      ),
    );
  }

  void _handleRegistration() async {
    // Validation du formulaire
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir tous les champs correctement"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final password = _mdpController.text.trim();
    final confirmPassword = _confirmMdpController.text.trim();

    if (password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Les mots de passe sont obligatoires")),
      );
      return;
    }

    // Vérification taille des documents
    const maxSize = 255 * 1024; // 255 Ko
    final oversized = _selectedDocs.any((doc) => doc.size > maxSize);
    if (oversized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Chaque document doit faire moins de 255 Ko"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    // Vérification des fichiers
    if (_selectedLogo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez sélectionner un logo"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedDocs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez fournir les documents requis"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {

      await _apiService.registerCenter(
        name: _nomController.text,
        city: _selectedVille!,
        phone: _phoneController.text,
        logo: File(_selectedLogo!.path!),
        password: _mdpController.text.trim(),
        confirm_password: _confirmMdpController.text.trim(),
        documents: _selectedDocs.map((doc) => File(doc.path!)).toList(),
        description: _descriptionController.text,

      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _numeroController.dispose();
    _descriptionController.dispose();
    _mdpController.dispose();
    _confirmMdpController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}