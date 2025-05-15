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
          content: Text('Êtes-vous sûr de vouloir supprimer ce film ?'),
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
    try {
      await _movieService.deleteMovie(id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Film supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      await _loadMovies();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _editMovie(Map<String, dynamic> movie) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: movie['nom_film']);
    final durationController = TextEditingController(text: movie['duree_film']?.toString());
    final tarifEnfantController = TextEditingController(text: movie['tarif_enf_film']?.toString() ?? '0');
    final tarifAdulteController = TextEditingController(text: movie['tarif_adu_film']?.toString() ?? '0');
    final tarifPremiereController = TextEditingController(text: movie['tarif_premiere']?.toString() ?? '0');
    String? currentImageUrl = movie['image_url'];
    int? selectedFormatId = movie['id_format'];
    int? selectedGenreId = movie['id_genre'];
    int? selectedLanguageId = movie['id_langue'];
    int? selectedClassificationId = movie['id_classif'];
    int? selectedCategoryId = movie['id_cat_fil'];
    File? imageFile;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image picker
                  GestureDetector(
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        setState(() {
                          imageFile = File(image.path);
                          currentImageUrl = null;
                        });
                      }
                    },
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                      child: imageFile != null 
                          ? Image.file(imageFile!, fit: BoxFit.cover)
                          : (currentImageUrl != null
                              ? Image.network(currentImageUrl!, fit: BoxFit.cover)
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey[600]),
                                    SizedBox(height: 8),
                                    Text('Modifier l\'image', style: TextStyle(color: Colors.grey[600])),
                                  ],
                                )),
                    ),
                  ),
                  SizedBox(height: 16),

                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nom du film',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  SizedBox(height: 16),

                  TextFormField(
                    controller: durationController,
                    decoration: InputDecoration(
                      labelText: 'Durée (minutes)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixText: 'min',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16),

                  TextFormField(
                    controller: tarifEnfantController,
                    decoration: InputDecoration(
                      labelText: 'Tarif Enfant',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixText: 'FCFA',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16),

                  TextFormField(
                    controller: tarifAdulteController,
                    decoration: InputDecoration(
                      labelText: 'Tarif Adulte',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixText: 'FCFA',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16),

                  TextFormField(
                    controller: tarifPremiereController,
                    decoration: InputDecoration(
                      labelText: 'Tarif Première',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixText: 'FCFA',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 24),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      try {
                        final data = {
                          'nom_film': nameController.text.isNotEmpty ? nameController.text : movie['nom_film'],
                          'duree_film': durationController.text.isNotEmpty ? durationController.text : movie['duree_film'],
                          'tarif_enf_film': tarifEnfantController.text.isNotEmpty ? int.parse(tarifEnfantController.text) : movie['tarif_enf_film'],
                          'tarif_adu_film': tarifAdulteController.text.isNotEmpty ? int.parse(tarifAdulteController.text) : movie['tarif_adu_film'],
                          'tarif_premiere': tarifPremiereController.text.isNotEmpty ? int.parse(tarifPremiereController.text) : movie['tarif_premiere'],
                          'id_format': selectedFormatId ?? movie['id_format'],
                          'id_genre': selectedGenreId ?? movie['id_genre'],
                          'id_langue': selectedLanguageId ?? movie['id_langue'],
                          'id_classif': selectedClassificationId ?? movie['id_classif'],
                          'id_cat_fil': selectedCategoryId ?? movie['id_cat_fil'],
                        };

                        if (imageFile != null) {
                          data['image_url'] = imageFile;
                        }

                        final success = await _movieService.updateMovie(movie['id_film'], data);
                        
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Film mis à jour avec succès'), backgroundColor: Colors.green),
                          );
                          Navigator.pop(context);
                          _loadMovies(); // Recharger la liste après la mise à jour
                        } else {
                          throw Exception('Échec de la mise à jour');
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: Text('Mettre à jour', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
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
  final TextEditingController _tarifEnfantController = TextEditingController();
  final TextEditingController _tarifAdulteController = TextEditingController();
  final TextEditingController _tarifPremiereController = TextEditingController();
  final TextEditingController _prixController = TextEditingController();
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
          // Section Image
          _buildSectionTitle('Image du film'),
          _buildImagePicker(),
          SizedBox(height: 24),

          // Section Informations générales
          _buildSectionTitle('Informations générales'),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nom du film',
              prefixIcon: Icon(Icons.movie, color: Colors.deepPurple),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer le nom du film';
              }
              return null;
            },
          ),
          SizedBox(height: 16),

          TextFormField(
            controller: _durationController,
            decoration: InputDecoration(
              labelText: 'Durée (minutes)',
              prefixIcon: Icon(Icons.timer, color: Colors.deepPurple),
              suffixText: 'min',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer la durée';
              }
              if (int.tryParse(value) == null) {
                return 'Veuillez entrer un nombre valide';
              }
              return null;
            },
          ),
          SizedBox(height: 24),

          // Section Configuration des tarifs
          _buildSectionTitle('Configuration des tarifs'),
          TextFormField(
            controller: _tarifEnfantController,
            decoration: InputDecoration(
              labelText: 'Tarif Enfant',
              prefixIcon: Icon(Icons.child_care, color: Colors.deepPurple),
              suffixText: 'FCFA',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer le tarif enfant';
              }
              if (int.tryParse(value) == null) {
                return 'Veuillez entrer un nombre valide';
              }
              return null;
            },
          ),
          SizedBox(height: 16),

          TextFormField(
            controller: _tarifAdulteController,
            decoration: InputDecoration(
              labelText: 'Tarif Adulte',
              prefixIcon: Icon(Icons.person, color: Colors.deepPurple),
              suffixText: 'FCFA',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer le tarif adulte';
              }
              if (int.tryParse(value) == null) {
                return 'Veuillez entrer un nombre valide';
              }
              return null;
            },
          ),
          SizedBox(height: 16),

          TextFormField(
            controller: _tarifPremiereController,
            decoration: InputDecoration(
              labelText: 'Tarif Première',
              prefixIcon: Icon(Icons.star, color: Colors.deepPurple),
              suffixText: 'FCFA',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer le tarif première';
              }
              if (int.tryParse(value) == null) {
                return 'Veuillez entrer un nombre valide';
              }
              return null;
            },
          ),
          SizedBox(height: 24),

          // Section Caractéristiques
          _buildSectionTitle('Caractéristiques du film'),
          _buildDropdown(
            items: _format,
            value: _selectedFormatId,
            onChanged: (value) => setState(() => _selectedFormatId = value),
            labelText: 'Format',
            validator: (value) => value == null ? 'Veuillez sélectionner un format' : null,
            idField: 'id_format',
            labelField: 'lib_format',
            icon: Icons.aspect_ratio,
          ),
          SizedBox(height: 16),

          _buildDropdown(
            items: _genre,
            value: _selectedGenreId,
            onChanged: (value) => setState(() => _selectedGenreId = value),
            labelText: 'Genre',
            validator: (value) => value == null ? 'Veuillez sélectionner un genre' : null,
            idField: 'id_genre',
            labelField: 'lib_genre',
            icon: Icons.category,
          ),
          SizedBox(height: 16),

          _buildDropdown(
            items: _language,
            value: _selectedLanguageId,
            onChanged: (value) => setState(() => _selectedLanguageId = value),
            labelText: 'Langue',
            validator: (value) => value == null ? 'Veuillez sélectionner une langue' : null,
            idField: 'id_langue',
            labelField: 'lib_langue',
            icon: Icons.language,
          ),
          SizedBox(height: 16),

          _buildDropdown(
            items: _classification,
            value: _selectedClassificationId,
            onChanged: (value) => setState(() => _selectedClassificationId = value),
            labelText: 'Classification',
            validator: (value) => value == null ? 'Veuillez sélectionner une classification' : null,
            idField: 'id_classif',
            labelField: 'lib_classif',
            icon: Icons.local_offer,
          ),
          SizedBox(height: 16),

          _buildDropdown(
            items: _categorie_film,
            value: _selectedCategoryId,
            onChanged: (value) => setState(() => _selectedCategoryId = value),
            labelText: 'Catégorie',
            validator: (value) => value == null ? 'Veuillez sélectionner une catégorie' : null,
            idField: 'id_cat_fil',
            labelField: 'lib_cat_fil',
            icon: Icons.movie_filter,
          ),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
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
          border: Border.all(color: Colors.grey[400]!, width: 1),
        ),
        child: _imagePath == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey[600]),
                  SizedBox(height: 8),
                  Text(
                    'Ajouter une image',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.file(
                  File(_imagePath!),
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
      ),
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
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: Size(double.infinity, 50),
        ),
        onPressed: _isLoading ? null : _submitForm,
        child: _isLoading
            ? CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Créer le film et programmer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      print('Validation du formulaire échouée');
      return;
    }
    if (_imagePath == null) {
      print('Aucune image sélectionnée');
      _showErrorSnackBar('Veuillez sélectionner une image');
      return;
    }

    setState(() => _isLoading = true);
    try {
      print('Préparation des données du film...');
      final movieData = {
        'nom_film': _nameController.text,
        'duree_film': int.parse(_durationController.text),
        'id_format': _selectedFormatId!,
        'id_centre': widget.centreId,
        'id_genre': _selectedGenreId!,
        'id_langue': _selectedLanguageId!,
        'id_classif': _selectedClassificationId!,
        'id_cat_fil': _selectedCategoryId!,
        'image_url': File(_imagePath!),
        'tarif_enf_film': int.parse(_tarifEnfantController.text),
        'tarif_adu_film': int.parse(_tarifAdulteController.text),
        'tarif_premiere': int.parse(_tarifPremiereController.text),
        'prix': int.parse(_prixController.text),
      };
      print('Données du film préparées : ${movieData.toString()}');

      print('Appel du service pour ajouter le film...');
      final movieId = await _movieService.addMovie(movieData);
      print('ID du film retourné : $movieId');

      if (movieId > 0) {
        if (!mounted) return;
        print('Film ajouté avec succès, navigation vers la programmation...');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Film ajouté avec succès'), backgroundColor: Colors.green),
        );
        widget.onSuccess();
        Navigator.of(context).pop();
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddProgrammeScreen(movieId: movieId),
          ),
        );
      } else {
        print('Échec de l\'ajout du film : ID invalide ($movieId)');
        throw Exception('Échec de l\'ajout du film');
      }
    } catch (e) {
      print('Exception dans _submitForm: ${e.toString()}');
      if (!mounted) return;
      _showErrorSnackBar('Erreur: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildDropdown({
    required List<Map<String, dynamic>> items,
    required int? value,
    required ValueChanged<int?> onChanged,
    required String labelText,
    required String? Function(int?) validator,
    required String idField,
    required String labelField,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<int>(
          decoration: InputDecoration(
            labelText: labelText,
            prefixIcon: Icon(icon, color: Colors.deepPurple),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem<int>(
              value: item[idField] as int,
              child: Text(item[labelField] ?? ''),
            );
          }).toList(),
          onChanged: (val) {
            onChanged(val);
            if (idField == 'id_cat_fil' && val != null) {
              _prixController.clear();
            }
          },
          value: value,
          isExpanded: true,
          validator: validator,
        ),
        if (idField == 'id_cat_fil' && value != null) ...[
          SizedBox(height: 16),
          TextFormField(
            controller: _prixController,
            decoration: InputDecoration(
              labelText: 'Prix de la catégorie',
              prefixIcon: Icon(Icons.attach_money, color: Colors.deepPurple),
              suffixText: 'FCFA',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer le prix de la catégorie';
              }
              if (int.tryParse(value) == null) {
                return 'Veuillez entrer un nombre valide';
              }
              return null;
            },
          ),
        ],
      ],
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
          items: _jour.map((j) {
            return DropdownMenuItem<int>(
              value: j['id_jour'] as int,
              child: Text(j['lib_jour'] ?? ''),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedDayId = val;
                _selectedDayLabel = _jour.firstWhere(
                  (element) => element['id_jour'] == val,
                  orElse: () => {'lib_jour': ''},
                )['lib_jour'];
              });
            }
          },
          value: _selectedDayId,
          isExpanded: true,
          hint: Text('Sélectionnez un jour'),
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