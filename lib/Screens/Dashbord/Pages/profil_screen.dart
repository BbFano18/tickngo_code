import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../API/api_config.dart';
import '../../interfaces/acceuil_screen.dart';
import '../../login/connexion_centre_screen.dart';

class ProfileScreen2 extends StatefulWidget {
  final VoidCallback? onLogoutCallback;

  ProfileScreen2({this.onLogoutCallback});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen2> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  String? _logoPath;

  final Color _primaryColor = Color(0xFF7F56D9);
  final Color _accentColor = Color(0xFFF97316);
  final Color _textColor = Colors.grey[800]!;
  final Color _lightGrey = Colors.grey[300]!;
  final double _spacing = 16.0;

  String _currentName = 'Nom du Centre Actuel';
  String _currentPhone = '+229 90 12 34 56';
  String? logoUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      final userData = jsonDecode(userDataString);
      setState(() {
        _currentName = userData['nom_centre'] ?? 'Nom inconnu';
        _currentPhone = '+229 ${userData['num_centre'] ?? 'XX XX XX XX'}';
        logoUrl = userData['logo'];

        if (logoUrl != null && logoUrl!.isNotEmpty) {
          // No need to set _currentLogoPath since we use getFullLogoUrl
        } else {
          _logoPath = 'assets/default_logo.png';
        }

        _nameController.text = _currentName;
        _phoneController.text = _currentPhone;
      });
    }
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _logoPath = pickedFile.path;
        logoUrl = null;  // Reset URL when a new logo is picked
      }
    });
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Se Déconnecter', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              widget.onLogoutCallback?.call();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => HomeScreen()),
                    (route) => false,
              );
            },
            child: Text('Se Déconnecter', style: TextStyle(color: _accentColor)),
          ),
        ],
      ),
    );
  }

  void _saveProfile() {
    setState(() {
      _currentName = _nameController.text;
      _currentPhone = _phoneController.text;
      if (_logoPath != null) {
        logoUrl = null;  // Ensure URL is reset if logo is uploaded locally
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Informations du profil sauvegardées')),
    );
  }

  // Méthode pour obtenir l'URL complète du logo
  String getFullLogoUrl() {
    if (logoUrl == null || logoUrl!.isEmpty) return '';
    if (logoUrl!.startsWith('http')) return logoUrl!;
    // Sinon, on la préfixe avec la base URL appropriée
    return '${ApiConfig.baseUrl2}storage/$logoUrl';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text('Profil centre',
            style: GoogleFonts.montserrat(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        backgroundColor: _primaryColor,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(_spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: _spacing * 1.5),
            Center(child: _buildLogoSection()),
            SizedBox(height: _spacing),
            _buildTextField('Nom du Centre', _nameController, Icons.store_outlined),
            SizedBox(height: _spacing),
            _buildTextField('Téléphone', _phoneController, Icons.phone_outlined, keyboardType: TextInputType.phone),
            SizedBox(height: _spacing * 2),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                ),
                child: Text('Sauvegarder les informations', style: TextStyle(fontSize: 18.0, color: Colors.white)),
              ),
            ),
            SizedBox(height: _spacing),
            Divider(height: _spacing * 2, color: _lightGrey),
            Text('Autres actions', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500)),
            SizedBox(height: _spacing),
            _buildActionItem(Icons.lock_outline, 'Changer le Mot de Passe', () {}),
            Padding(
              padding: EdgeInsets.only(bottom: 60),
              child: _buildActionItem(Icons.logout_outlined, 'Se Déconnecter', () => _handleLogout(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Stack(
      children: [
        Container(
          width: 120.0,
          height: 120.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _lightGrey, width: 2.0),
          ),
          child: ClipOval(
            child: _logoPath != null
                ? Image.file(File(_logoPath!), fit: BoxFit.cover)
                : Image.network(
              getFullLogoUrl(),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(Icons.broken_image),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: InkWell(
            onTap: _pickLogo,
            child: Container(
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: _accentColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.0),
              ),
              child: Icon(Icons.edit, size: 20, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String labelText, TextEditingController controller, IconData icon, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: _primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _primaryColor)),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: _primaryColor),
            SizedBox(width: _spacing),
            Text(text, style: TextStyle(fontSize: 16.0, color: _textColor)),
          ],
        ),
      ),
    );
  }
}
