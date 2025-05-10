import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Services/ajoutfilm_service.dart';

//Affichage des films
class MovieDashboard extends StatefulWidget {
  const MovieDashboard({Key? key}) : super(key: key);

  @override
  _MovieDashboardState createState() => _MovieDashboardState();
}

class _MovieDashboardState extends State<MovieDashboard> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _movies = [];
  final MovieService _movieService = MovieService();
  int? _userId; // Pour stocker l'ID de l'utilisateur

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    setState(() => _isLoading = true);
    try {
      final userId = await _getUserId(); // Utilisez _getUserId() ici
      final List<Map<String, dynamic>> movies = await _movieService.fetchMovies(userId);
      setState(() {
        _movies = movies;
      });
    } catch (e) {
      print('Erreur lors du chargement des films: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des films'),
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

  void _showAddMovieForm() {
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
                    child: AddMovieForm(
                      centreId: _userId!,
                      onSuccess: () {
                        Navigator.pop(context);
                        _loadMovies();
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
            'Ajouter un Film',
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

  void _deleteMovie(int id) async {
    bool confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirmer la suppression'),
          content: Text('Êtes-vous sûr de vouloir supprimer ce film?'),
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
        );
      },
    ) ?? false;

    if (!confirm) return;
    setState(() => _isLoading = true);
    /*try {
      final success = await _movieService.deleteMovie(id);
      final message = success ? 'Film supprimé avec succès' : 'Échec de la suppression';
      final color = success ? Colors.green : Colors.red;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
      if (success) _loadMovies();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }*/
  }

  void _editMovie(Map<String, dynamic> movie) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Fonctionnalité d\'édition à venir')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _movies.isEmpty ? _buildEmptyState() : Column(
        children: [
          Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                child: ElevatedButton.icon(
                  icon: Icon(Icons.add, color: Colors.white),
                  label: Text('Ajouter votre premier film'),
                  onPressed: _showAddMovieForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          Expanded(child: _buildMovieList()),
        ],
      ),
      /*floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMovieForm,
        label: Text('Ajouter un film'),
        icon: Icon(Icons.add),
        backgroundColor: Colors.deepPurple,
      ),*/
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.movie_creation_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Aucun film disponible',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Cliquez sur "Ajouter un film" pour commencer',
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.add, color: Colors.white),
            label: Text('Ajouter votre premier film'),
            onPressed: _showAddMovieForm,
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

  Widget _buildMovieList() {
    return RefreshIndicator(
      onRefresh: _loadMovies,
      child: ListView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: 80.0),
        children: [
          ..._movies.map((movie) => _buildMovieCard(movie)).toList(),
        ],
      ),
    );
  }

  _buildMovieCard(Map<String, dynamic> movie) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.all(12),
        leading: _buildMovieImage(movie['image_url']),
        title: Text(movie['nom_film'] ?? 'Sans titre', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text('Durée: ${movie['duree_film'] ?? 'N/A'} min'),
            Text('Genre: ${movie['lib_genre'] ?? 'Non spécifié'}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: Icon(Icons.edit, color: Colors.blue), onPressed: () => _editMovie(movie)),
            IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteMovie(movie['id_film'])),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieImage(String? url) {
    if (url == null) {
      return Container(
        width: 60,
        height: 80,
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
        child: Icon(Icons.movie, color: Colors.grey[600]),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(url, width: 60, height: 80, fit: BoxFit.cover, errorBuilder: (_,__,___) {
        return Container(
          width: 60,
          height: 80,
          color: Colors.grey[300],
          child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
        );
      }),
    );
  }
}

//Formulaire d'ajout d'un film
class AddMovieForm extends StatefulWidget {
  final int centreId;
  final VoidCallback onSuccess;

  const AddMovieForm({required this.centreId, required this.onSuccess});

  @override
  _AddMovieFormState createState() => _AddMovieFormState();
}

class _AddMovieFormState extends State<AddMovieForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  int? _selectedFormatId;
  int? _selectedGenreId;
  int? _selectedLanguageId;
  int? _selectedClassificationId;
  int? _selectedCategoryId;
  String? _imagePath;
  bool _isLoading = false;
  final MovieService _movieService = MovieService();
  List<Map<String, dynamic>> _format = [];
  List<Map<String, dynamic>> _genre = [];
  List<Map<String, dynamic>> _language = [];
  List<Map<String, dynamic>> _classification= [];
  List<Map<String, dynamic>> _categorie_film = [];

  @override
  void initState() {
    super.initState();
    _loadReferenceData();
  }

  Future<void> _loadReferenceData() async {
    setState(() => _isLoading = true);
    try {
      _format = await _movieService.fetchFormat() ?? [];
      _genre = await _movieService.fetchGenre() ?? [];
      _language = await _movieService.fetchLanguage() ?? [];
      _classification= await _movieService.fetchClassification() ?? [];
      _categorie_film = await _movieService.fetchCategoriefilm() ?? [];
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur de chargement'), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildTextField(_nameController, 'Titre', Icons.movie),
          SizedBox(height: 16),
          _buildTextField(_durationController, 'Durée (Heure)', Icons.timer, keyboardType: TextInputType.number),
          SizedBox(height: 16),
          _buildDropdown('Format', _format, 'id_format', 'lib_format', (val) => _selectedFormatId = val),
          SizedBox(height: 16),
          _buildDropdown('Genre', _genre, 'id_genre', 'lib_genre', (val) => _selectedGenreId = val),
          SizedBox(height: 16),
          _buildDropdown('Langue', _language, 'id_langue', 'lib_langue', (val) => _selectedLanguageId = val),
          SizedBox(height: 16),
          _buildDropdown('Classification', _classification, 'id_classif', 'lib_classif', (val) => _selectedClassificationId = val),
          SizedBox(height: 16),
          _buildDropdown('Catégorie', _categorie_film, 'id_cat_fil', 'lib_cat_fil', (val) => _selectedCategoryId = val),
          SizedBox(height: 16),
          _buildImageUploadField(),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
      validator: (val) {
        if (val == null || val.isEmpty) return 'Veuillez entrer $label';
        if (label.contains('Durée') && int.tryParse(val) == null) {
          return 'Nombre invalide';
        }
        return null;
      },
    );
  }

  Widget _buildDropdown(String label, List<Map<String, dynamic>> items, String valueKey, String labelKey, ValueChanged<int?> onChanged) {
    return DropdownButtonFormField<int>(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
      items: items.map((item) => DropdownMenuItem<int>(value: item[valueKey] as int, child: Text(item[labelKey] ?? ''))).toList(),
      onChanged: onChanged,
      value: null,
      isExpanded: true,
      validator: (val) => val == null ? 'Veuillez sélectionner $label' : null,
    );
  }

  Widget _buildImageUploadField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Image', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickImage(),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: _imagePath == null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 40, color: Colors.grey[600]),
                  Text('Sélectionner une image', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            )
                : Image.file(File(_imagePath!), width: double.infinity, fit: BoxFit.cover),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });
    }
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 14),
          textStyle: TextStyle(fontSize: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: _isLoading ? null : _submitForm,
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Text('Ajouter le film'),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imagePath == null) {
      _showErrorSnackbar('Veuillez sélectionner une image');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final movieData = {
        'nom_film': _nameController.text,
        'duree_film': int.parse(_durationController.text),
        'id_format': _selectedFormatId!,
        'id_centre': widget.centreId,
        'id_genre': _selectedGenreId!,
        'id_langue': _selectedLanguageId!,
        'id_classif': _selectedClassificationId!,
        'id_cat_fil': _selectedCategoryId!,
        'image_url': _imagePath!,
      };

      final movieId = await _movieService.addMovie(movieData);
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddProgrammeScreen(movieId: movieId),
        ),
      );
      widget.onSuccess();
    } catch (e) {
      _showErrorSnackbar('Erreur: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
//Programmation
class AddProgrammeScreen extends StatefulWidget {
  final dynamic movieId;

  AddProgrammeScreen({required this.movieId});

  @override
  _AddProgrammeScreenState createState() => _AddProgrammeScreenState();
}

class _AddProgrammeScreenState extends State<AddProgrammeScreen> {
  final MovieService _movieService = MovieService();
  bool _isLoading = false;
  String? _movieTitle;

  int? _selectedDayId;
  String? _selectedDayLabel;
  TimeOfDay? _selectedTime;
  List<Map<String, dynamic>> _jour = [];
  List<Map<String, dynamic>> _programmes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Charger les jours
      _jour = await _movieService.fetchJour() ?? [];

      // Charger les détails du film pour afficher le titre
      final movieDetails = await _movieService.fetchMovieDetails(widget.movieId);
      if (movieDetails != null) {
        setState(() {
          _movieTitle = movieDetails['nom_film'];
        });
      }

      // Charger les programmes existants pour ce film (si applicable)
      final existingProgrammes = await _movieService.fetchMovieProgrammes(widget.movieId);
      if (existingProgrammes != null) {
        setState(() {
          _programmes = existingProgrammes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur de chargement des données'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Programmation du film'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_movieTitle != null)
              Card(
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.movie, color: Colors.deepPurple, size: 30),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Film',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              _movieTitle!,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
                        SizedBox(width: 8),
                        Text(
                          'Ajouter une programmation',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildDayTimeSelectors(),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: Icon(Icons.add),
                      label: Text('Ajouter à la programmation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _addProgrammesItem,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            if (_programmes.isNotEmpty) ...[
              Text(
                'Programmes enregistrés',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              ..._programmes.map((item) => Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(Icons.event, color: Colors.deepPurple),
                  title: Text(item['lib_jour'] ?? 'Jour inconnu'),
                  subtitle: Text(item['heure'] ?? 'Heure inconnue'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteProgrammeItem(item),
                  ),
                ),
              )),
              SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              icon: Icon(Icons.save),
              label: Text('Enregistrer la programmation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _saveProgrammes,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayTimeSelectors() {
    return Column(
      children: [
        DropdownButtonFormField<int>(
          decoration: InputDecoration(
            labelText: 'Jour',
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          items: _jour
              .map((j) => DropdownMenuItem<int>(
            value: j['id_jour'] as int,
            child: Text(j['lib_jour'] ?? ''),
          ))
              .toList(),
          onChanged: (val) {
            setState(() {
              _selectedDayId = val;
              _selectedDayLabel = _jour.firstWhere((element) => element['id_jour'] == val)['lib_jour'];
            });
          },
          value: _selectedDayId,
          isExpanded: true,
        ),
        SizedBox(height: 16),
        _buildTimeSelector(),
      ],
    );
  }

  Widget _buildTimeSelector() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              TimeOfDay? selectedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (selectedTime != null) {
                setState(() {
                  _selectedTime = selectedTime;
                });
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Heure',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_selectedTime == null ? 'Sélectionner une heure' : _selectedTime!.format(context)),
                  Icon(Icons.access_time),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _addProgrammesItem() {
    if (_selectedDayId != null && _selectedTime != null) {
      setState(() {
        _programmes.add({
          'id_jour': _selectedDayId,
          'lib_jour': _selectedDayLabel,
          'heure': _selectedTime!.format(context),
        });
        // Réinitialiser les valeurs après l'ajout
        _selectedDayId = null;
        _selectedDayLabel = null;
        _selectedTime = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez sélectionner le jour et l\'heure'), backgroundColor: Colors.red),
      );
    }
  }

  void _deleteProgrammeItem(Map<String, dynamic> item) {
    setState(() {
      _programmes.remove(item);
    });
  }

  Future<void> _saveProgrammes() async {
    setState(() => _isLoading = true);
    try {
      await _movieService.updateMovieProgrammes(widget.movieId, _programmes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Programmation enregistrée avec succès'), backgroundColor: Colors.green),
      );

      // Naviguer en arrière après un court délai pour que l'utilisateur puisse voir le message
      Future.delayed(Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'enregistrement de la programmation'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}