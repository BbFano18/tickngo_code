import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Services/ajoutjeux_service.dart';

class GameDashboard extends StatefulWidget {
  const GameDashboard({Key? key}) : super(key: key);

  @override
  _GameDashboardState createState() => _GameDashboardState();
}

class _GameDashboardState extends State<GameDashboard> {
  final GameService _gameService = GameService();
  List<Map<String, dynamic>> _games = [];
  bool _isLoading = false;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    setState(() => _isLoading = true);
    try {
      final userId = await _getUserId();
      final List<Map<String, dynamic>> games = await _gameService.fetchGames(userId);
      setState(() {
        _games = games;
      });
    } catch (e) {
      print('Erreur lors du chargement des jeux: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des jeux'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<int> _getUserId() async {
    if (_userId != null) return _userId!;
    final prefs = await SharedPreferences.getInstance();
    final storedId = prefs.getInt('user_id');
    if (storedId != null) {
      _userId = storedId;
      return storedId;
    } else {
      throw Exception('Aucun user_id trouvé dans SharedPreferences');
    }
  }

  void _showAddGameForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                children: [
                  _buildSheetHeader(),
                  Divider(),
                  Expanded(
                    child: AddGameForm(
                      centreId: _userId!,
                      onSuccess: (int gameId) {
                        Navigator.pop(context);
                        _loadGames();
                        // Naviguer vers l'écran de programmation
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddScheduleScreen(gameId: gameId),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSheetHeader() {
    return Container(
      padding: EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'Ajouter un Jeu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(width: 48),
        ],
      ),
    );
  }

  void _deleteGame(int id) async {
    bool confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer ce jeu?'),
        actions: [
          TextButton(
            child: Text('Annuler'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    ) ??
        false;
    if (!confirm) return;
    setState(() => _isLoading = true);
    try {
      final success = await _gameService.deleteGame(id);
      final message = success ? 'Jeu supprimé avec succès' : 'Échec de la suppression';
      final color = success ? Colors.green : Colors.red;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
      if (success) _loadGames();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _editGame(Map<String, dynamic> game) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('En cours de conception ... ')),
    );
  }

  void _viewSchedule(int gameId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddScheduleScreen(gameId: gameId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_games.isEmpty)
          ? _buildEmptyState()
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Ajouter un jeu'),
              onPressed: _showAddGameForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
          Expanded(child: _buildGameList()),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_esports, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Aucun jeu disponible',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Cliquez sur "Ajouter un jeu" pour commencer',
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.add, color: Colors.white),
            label: Text('Ajouter un jeu'),
            onPressed: _showAddGameForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameList() {
    return RefreshIndicator(
      onRefresh: _loadGames,
      child: ListView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: 80.0),
        children: [
          ..._games.map((game) => _buildGameCard(game)).toList(),
        ],
      ),
    );
  }

  Widget _buildGameCard(Map<String, dynamic> game) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.all(12),
        leading: _buildGameImage(game['image_url']),
        title: Text(game['nom_jeux'] ?? 'Sans titre', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text('Lieu: ${game['lieu_jeux'] ?? 'N/A'}'),
            Text('Durée: ${game['duree_jeux'] ?? 'Non spécifiée'}'),
            Text('Tarif: ${game['tarif'] ?? 'N/A'} FCFA'),
            if (game['age_mini'] != null) Text('Âge minimum: ${game['age_mini']} ans'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.schedule, color: Colors.purple),
              onPressed: () => _viewSchedule(game['id_jeux'].toInt()),
              tooltip: 'Voir programmation',
            ),
            IconButton(icon: Icon(Icons.edit, color: Colors.blue), onPressed: () => _editGame(game)),
            IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteGame(game['id_jeux'])),
          ],
        ),
      ),
    );
  }

  Widget _buildGameImage(String? url) {
    if (url == null) {
      return Container(
        width: 60,
        height: 80,
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
        child: Icon(Icons.sports_esports, color: Colors.grey[600]),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 60,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 60,
          height: 80,
          color: Colors.grey[300],
          child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
        ),
      ),
    );
  }
}

//ajout jeux
class AddGameForm extends StatefulWidget {
  final Function(int gameId) onSuccess;
  final int centreId;

  const AddGameForm({required this.onSuccess, required this.centreId});

  @override
  _AddGameFormState createState() => _AddGameFormState();
}

class _AddGameFormState extends State<AddGameForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceChildController = TextEditingController();
  final _priceAdultController = TextEditingController();
  final _ageController = TextEditingController();

  String? _selectedDuration;
  File? _imageFile;
  String? _imagePath;
  bool _isLoading = false;

  final GameService _gameService = GameService();
  final _imagePicker = ImagePicker();

  List<String> _durations = ['15', '30', '60', '90', '120'];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _imagePath = pickedFile.path;
      });
    }
  }

  void _submitForm() async {
    debugPrint("Entrée dans la fct");
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDuration == null) {
      _showErrorSnackBar('Veuillez sélectionner une durée');
      return;
    }

    if (_imageFile == null) {
      _showErrorSnackBar('Veuillez sélectionner une image');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'nom_jeux': _nameController.text,
        'duree_jeux': _selectedDuration,
        'id_centre': widget.centreId,
        'tarif_enf_jeux': int.parse(_priceChildController.text),
        'tarif_adu_jeux': int.parse(_priceAdultController.text),
        'age_mini': _ageController.text.isNotEmpty ? int.parse(_ageController.text) : null,
        'logo_jeux': _imagePath,
      };

      final gameId = await _gameService.addGame(data);

      if (gameId > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Jeu ajouté avec succès'), backgroundColor: Colors.green),
        );

        widget.onSuccess(gameId.toInt());

        // Redirection vers AddScheduleScreen avec l'ID du jeu
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddScheduleScreen(gameId: gameId),
          ),
        );
      } else {
        _showErrorSnackBar('Échec de l\'ajout du jeu');
      }
    } catch (e) {
      debugPrint('Erreur: ${e.toString()}');
      _showErrorSnackBar('Erreur: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImagePicker(),
            SizedBox(height: 20),
            _buildSectionTitle('Informations générales'),
            _buildTextField(_nameController, 'Nom du jeu', Icons.sports_esports, true),
            SizedBox(height: 16),
            _buildDurationDropdown(),
            SizedBox(height: 20),
            _buildSectionTitle('Tarification'),
            _buildTextField(_priceChildController, 'Tarif enfant (FCFA)', Icons.child_care, true, type: TextInputType.number),
            SizedBox(height: 16),
            _buildTextField(_priceAdultController, 'Tarif adulte (FCFA)', Icons.person, true, type: TextInputType.number),
            SizedBox(height: 16),
            _buildTextField(_ageController, 'Âge minimum requis', Icons.cake, false, type: TextInputType.number),
            SizedBox(height: 32),
            _buildSubmitButton(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[400]!),
        ),
        child: _imageFile != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey[600]),
            SizedBox(height: 8),
            Text('Ajouter une image', style: TextStyle(color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon,
      bool required, {
        TextInputType type = TextInputType.text,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (required && (value == null || value.isEmpty)) {
          return 'Ce champ est requis';
        }
        return null;
      },
    );
  }

  Widget _buildDurationDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Durée du jeu (en minutes)',
        prefixIcon: Icon(Icons.access_time, color: Colors.deepPurple),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      value: _selectedDuration,
      items: _durations
          .map((dur) => DropdownMenuItem(value: dur, child: Text('$dur minutes')))
          .toList(),
      onChanged: (value) => setState(() => _selectedDuration = value),
      validator: (val) => val == null ? 'Sélectionnez une durée' : null,
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _submitForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isLoading
          ? CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
          : Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add, color: Colors.white),
          SizedBox(width: 8),
          Text('Créer le jeu et programmer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
      ),
    );
  }
}

//programme
class AddScheduleScreen extends StatefulWidget {
  final int? gameId;

  const AddScheduleScreen({this.gameId});

  @override
  _AddScheduleScreenState createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  List<Map<String, dynamic>> _scheduleItems = [];
  List<Map<String, dynamic>> _availableDays = [];
  bool _isLoading = true;
  TimeOfDay? _selectedTime;
  Map<String, dynamic>? _selectedDay;

  @override
  void initState() {
    super.initState();
    _loadAvailableDays();
  }

  // Charger la liste des jours disponibles depuis l'API
  Future<void> _loadAvailableDays() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final gameService = GameService();
      final days = await gameService.fetchAvailableDays();

      setState(() {
        _availableDays = days;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des jours: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de charger les jours disponibles')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectTime() async {
    if (_selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez d\'abord sélectionner un jour')),
      );
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    setState(() {
      _selectedTime = time;

      // Créer une entrée de programmation avec le jour sélectionné et l'heure
      _scheduleItems.add({
        'day': _selectedDay!,
        'time': time,
      });

      // Réinitialiser les sélections
      _selectedDay = null;
      _selectedTime = null;
    });
  }

  Future<void> _saveSchedule() async {
    if (_scheduleItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ajoutez au moins une séance')),
      );
      return;
    }

    // Formatage des données pour l'API
    final formatted = _scheduleItems.map((item) {
      final day = item['day'] as Map<String, dynamic>;
      final time = item['time'] as TimeOfDay;

      // Créer une date de référence (aujourd'hui) avec l'heure sélectionnée
      final now = DateTime.now();
      final dateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);

      return {
        'game_id': widget.gameId,
        'id_jour': day['id_jour'],
        'heure': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      };
    }).toList();

    // Envoyer à l'API
    try {
      final gameService = GameService();

      // Utiliser directement updateGameSchedules car nous avons déjà le format attendu
      final success = await gameService.updateGameSchedules(
          widget.gameId!,
          formatted.map((item) => {
            'id_jour': item['id_jour'],
            'heure': item['heure'],
          }).toList()
      );

      if (success) {
        Navigator.popUntil(context, (r) => r.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'enregistrement des séances')),
        );
      }
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Une erreur est survenue: $e')),
      );
    }
  }

  Widget _buildScheduleItem(Map<String, dynamic> item) {
    final day = item['day'] as Map<String, dynamic>;
    final time = item['time'] as TimeOfDay;

    return ListTile(
      leading: Icon(Icons.schedule),
      title: Text(day['lib_jour'] ?? 'Jour inconnu'),
      subtitle: Text('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'),
      trailing: IconButton(
        icon: Icon(Icons.delete, color: Colors.red),
        onPressed: () => setState(() => _scheduleItems.remove(item)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Programmation du Jeu')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nouvelle séance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 16),

                    // Sélection du jour (ComboBox)
                    DropdownButtonFormField<Map<String, dynamic>>(
                      decoration: InputDecoration(
                        labelText: 'Jour',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedDay,
                      hint: Text('Sélectionner un jour'),
                      items: _availableDays.map((day) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: day,
                          child: Text(day['lib_jour'] ?? 'Jour inconnu'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDay = value;
                        });
                      },
                    ),

                    SizedBox(height: 16),

                    // Bouton pour sélectionner l'heure
                    ElevatedButton.icon(
                      icon: Icon(Icons.access_time),
                      label: Text('Sélectionner l\'heure'),
                      onPressed: _selectTime,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            Text(
                'Séances programmées',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
            ),

            SizedBox(height: 10),

            Expanded(
              child: _scheduleItems.isEmpty
                  ? Center(child: Text('Aucune séance ajoutée'))
                  : ListView.builder(
                itemCount: _scheduleItems.length,
                itemBuilder: (_, i) => _buildScheduleItem(_scheduleItems[i]),
              ),
            ),

            SizedBox(height: 16),

            ElevatedButton(
              onPressed: _saveSchedule,
              child: Text('Finaliser la Programmation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}