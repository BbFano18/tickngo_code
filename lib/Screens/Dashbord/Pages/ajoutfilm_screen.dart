import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../API/api_config.dart';
import '../../Cinema/Services/movie_service.dart';
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
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    try {
      final userId = await _getUserId();
      final List<Map<String, dynamic>> movies = await _movieService.fetchMovies(userId);
      if (!mounted) return;
      
      // Récupérer les classifications pour chaque film
      for (var movie in movies) {
        if (movie['id_classif'] != null) {
          final classification = await _movieService.fetchClassificationById(movie['id_classif']);
          if (classification != null) {
            movie['lib_classif'] = classification['lib_classif'];
          }
        }
      }
      
      setState(() {
        _movies = movies;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des films: $e');
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des films'),
          backgroundColor: Colors.red,
        ),
      );
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
                      onSuccess: () async {
                        await _loadMovies(); // Actualiser après l'ajout
                        Navigator.pop(context);
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
      builder: (context) => AlertDialog(
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
      ),
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
      
      await _loadMovies(); // Actualiser après la suppression
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
                  Container(
                    padding: EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          'Modifier le Film',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Divider(),
                  Expanded(
                    child: AddMovieForm(
                      centreId: _userId!,
                      movieToEdit: movie,
                      onSuccess: () async {
                        await _loadMovies(); // Actualiser après la modification
                        Navigator.pop(context);
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

  Widget _buildMovieCard(Map<String, dynamic> movie) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showMovieDetails(movie),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              _buildMovieImage(movie['image_url']),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie['nom_film'] ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  movie['duree_film'] ?? '',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.local_offer, size: 16, color: Colors.grey[600]),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  movie['lib_classif'] ?? '',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.calendar_today, color: Colors.blue),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddProgrammeScreen(movieId: movie['id_film']),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editMovie(movie),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteMovie(movie['id_film']),
                  ),
                ],
              ),
            ],
          ),
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

  void _showMovieDetails(Map<String, dynamic> movie) {
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
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Détails du film',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (movie['image_url'] != null)
                            Container(
                              width: double.infinity,
                              height: 250,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: NetworkImage('${ApiConfig.baseUrl2}storage/${movie['image_url']}'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          SizedBox(height: 24),
                          _buildDetailSection('Informations générales', [
                            _buildDetailRow('Nom', movie['nom_film']),
                            _buildDetailRow('Durée', movie['duree_film']),
                            _buildDetailRow('Format', movie['lib_format']),
                            _buildDetailRow('Genre', movie['lib_genre']),
                            _buildDetailRow('Langue', movie['lib_langue']),
                            _buildDetailRow('Classification', movie['lib_classif']),
                            _buildDetailRow('Catégorie', movie['lib_cat_fil']),
                          ]),
                          _buildDetailSection('Tarifs', [
                            if (movie['lib_cat_fil']?.toLowerCase() == 'standard') ...[
                              if (movie['tarif_enf_film'] != null && movie['tarif_enf_film'] > 0)
                                _buildTarifRow('Tarif Enfant', movie['tarif_enf_film']),
                              if (movie['tarif_adu_film'] != null && movie['tarif_adu_film'] > 0)
                                _buildTarifRow('Tarif Adulte', movie['tarif_adu_film']),
                            ] else if (movie['lib_cat_fil']?.toLowerCase() == 'première') ...[
                              if (movie['tarif_premiere'] != null && movie['tarif_premiere'] > 0)
                                _buildTarifRow('Tarif Première', movie['tarif_premiere']),
                            ] else ...[
                              if (movie['prix'] != null && movie['prix'] > 0)
                                _buildTarifRow('Tarif', movie['prix']),
                            ],
                          ]),
                        ],
                      ),
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

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.isEmpty || value == 'null') return SizedBox.shrink();
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarifRow(String label, dynamic value) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.deepPurple,
            ),
          ),
          Text(
            '${value.toString()} FCFA',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }
}

//Formulaire d'ajout d'un film
class AddMovieForm extends StatefulWidget {
  final int centreId;
  final VoidCallback onSuccess;
  final Map<String, dynamic>? movieToEdit;

  const AddMovieForm({
    required this.centreId,
    required this.onSuccess,
    this.movieToEdit,
  });

  @override
  _AddMovieFormState createState() => _AddMovieFormState();
}

class _AddMovieFormState extends State<AddMovieForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _tarifEnfantController = TextEditingController();
  final TextEditingController _tarifAdulteController = TextEditingController();
  final TextEditingController _tarifPremiereController = TextEditingController();
  final TextEditingController _prixController = TextEditingController();
  
  File? _imageFile;
  String? _imagePath;
  String? _currentImageUrl;
  bool _isLoading = false;
  
  String? _selectedDuration;
  int? _selectedFormatId;
  int? _selectedGenreId;
  int? _selectedLanguageId;
  int? _selectedClassificationId;
  int? _selectedCategoryId;
  
  final MovieService _movieService = MovieService();
  final _imagePicker = ImagePicker();
  
  List<Map<String, dynamic>> _format = [];
  List<Map<String, dynamic>> _genre = [];
  List<Map<String, dynamic>> _language = [];
  List<Map<String, dynamic>> _classification= [];
  List<Map<String, dynamic>> _categorie_film = [];

  // Liste des durées prédéfinies
  List<String> _durations = ['1h', '1h30min', '2h', '2h30min', '3h'];

  bool get isStandardCategory {
    if (_selectedCategoryId == null) return false;
    final category = _categorie_film.firstWhere(
      (cat) => cat['id_cat_fil'] == _selectedCategoryId,
      orElse: () => {'lib_cat_fil': ''},
    );
    final isStandard = category['lib_cat_fil'].toString().toLowerCase() == 'standard';
    print('Vérification catégorie Standard: ID=$_selectedCategoryId, libellé=${category['lib_cat_fil']}, isStandard=$isStandard');
    return isStandard;
  }

  bool get isPremiereCategory {
    if (_selectedCategoryId == null) return false;
    final category = _categorie_film.firstWhere(
      (cat) => cat['id_cat_fil'] == _selectedCategoryId,
      orElse: () => {'lib_cat_fil': ''},
    );
    final isPremiere = category['lib_cat_fil'].toString().toLowerCase() == 'première';
    print('Vérification catégorie Première: ID=$_selectedCategoryId, libellé=${category['lib_cat_fil']}, isPremiere=$isPremiere');
    return isPremiere;
  }

  @override
  void initState() {
    super.initState();
    _loadReferenceData();
    if (widget.movieToEdit != null) {
      _loadExistingMovieData();
    }
  }

  void _loadExistingMovieData() {
    final movie = widget.movieToEdit!;
    print('Chargement des données du film: ${movie.toString()}');
    
    _nameController.text = movie['nom_film'] ?? '';
    _selectedDuration = movie['duree_film'];
    _selectedFormatId = movie['id_format'];
    _selectedGenreId = movie['id_genre'];
    _selectedLanguageId = movie['id_langue'];
    _selectedClassificationId = movie['id_classif'];
    _selectedCategoryId = movie['id_cat_fil'];
    
    // Chargement des tarifs selon la catégorie
    if (isStandardCategory) {
      _tarifEnfantController.text = movie['tarif_enf_film']?.toString() ?? '';
      _tarifAdulteController.text = movie['tarif_adu_film']?.toString() ?? '';
      print('Tarifs Standard - Enfant: ${_tarifEnfantController.text}, Adulte: ${_tarifAdulteController.text}');
    } else if (isPremiereCategory) {
      _tarifPremiereController.text = movie['tarif_premiere']?.toString() ?? '';
      print('Tarif Première: ${_tarifPremiereController.text}');
    } else {
      _prixController.text = movie['prix']?.toString() ?? '';
      print('Tarif autre catégorie: ${_prixController.text}');
    }
    
    _currentImageUrl = movie['image_url'];
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

          // Durée avec combo prédéfini
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Durée du film',
              prefixIcon: Icon(Icons.timer, color: Colors.deepPurple),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            value: _selectedDuration,
            items: _durations.map((duration) {
              return DropdownMenuItem<String>(
                value: duration,
                child: Text(duration),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedDuration = val),
            validator: (value) => value == null ? 'Veuillez sélectionner une durée' : null,
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
            labelText: 'Tranche d\'âge',
            validator: (value) => value == null ? 'Veuillez sélectionner une tranche d\'âge' : null,
            idField: 'id_classif',
            labelField: 'lib_classif',
            icon: Icons.local_offer,
          ),
          SizedBox(height: 16),

          _buildDropdown(
            items: _categorie_film,
            value: _selectedCategoryId,
            onChanged: (value) {
              setState(() {
                _selectedCategoryId = value;
                // Réinitialiser tous les contrôleurs de tarif
                _tarifEnfantController.clear();
                _tarifAdulteController.clear();
                _tarifPremiereController.clear();
                _prixController.clear();
              });
            },
            labelText: 'Catégorie',
            validator: (value) => value == null ? 'Veuillez sélectionner une catégorie' : null,
            idField: 'id_cat_fil',
            labelField: 'lib_cat_fil',
            icon: Icons.movie_filter,
          ),
          SizedBox(height: 24),
          // Section Tarifs (conditionnelle selon la catégorie)

          if (isStandardCategory) ...[
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
          ] else if (isPremiereCategory) ...[
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
          ] else
            if (_selectedCategoryId != null) ...[
              _buildSectionTitle('Configuration des tarifs'),
            TextFormField(
              controller: _prixController,
              decoration: InputDecoration(
                labelText: 'Tarif de la catégorie',
                prefixIcon: Icon(Icons.attach_money, color: Colors.deepPurple),
                suffixText: 'FCFA',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer le tarif de la catégorie';
                }
                if (int.tryParse(value) == null) {
                  return 'Veuillez entrer un nombre valide';
                }
                return null;
              },
            ),
          ],
          SizedBox(height: 24),
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

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _imagePath = pickedFile.path;
        _currentImageUrl = null;
      });
    }
  }

  Widget _buildImageWidget() {
    if (_imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Image.file(
          _imageFile!,
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      );
    } else if (_currentImageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Image.network(
          '${ApiConfig.baseUrl2}storage/${_currentImageUrl}',
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        ),
      );
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey[600]),
        SizedBox(height: 8),
        Text(
          'Ajouter une image',
          style: TextStyle(color: Colors.grey[700]),
        ),
      ],
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
        child: _buildImageWidget(),
      ),
    );
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
                  Icon(Icons.save, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    widget.movieToEdit != null ? 'Mettre à jour le film' : 'Créer le film et programmer',
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      print('Début de la soumission du formulaire');
      print('Catégorie sélectionnée: $_selectedCategoryId');
      print('isStandardCategory: $isStandardCategory');
      print('isPremiereCategory: $isPremiereCategory');

      final movieData = {
        'nom_film': _nameController.text,
        'duree_film': _selectedDuration,
        'id_centre': widget.centreId,
        'id_format': _selectedFormatId,
        'id_genre': _selectedGenreId,
        'id_langue': _selectedLanguageId,
        'id_classif': _selectedClassificationId,
        'id_cat_fil': _selectedCategoryId,
      };

      // Validation et gestion des tarifs selon la catégorie
      if (isStandardCategory) {
        print('Validation des tarifs Standard');
        if (_tarifEnfantController.text.isEmpty || _tarifAdulteController.text.isEmpty) {
          throw Exception('Les tarifs enfant et adulte sont requis pour la catégorie Standard');
        }
        movieData['tarif_enf_film'] = int.tryParse(_tarifEnfantController.text);
        movieData['tarif_adu_film'] = int.tryParse(_tarifAdulteController.text);
        // Ajout des tarifs par défaut pour la catégorie Standard
        movieData['tarif_premiere'] = 0;
        movieData['prix'] = 0;
      } else if (isPremiereCategory) {
        print('Validation des tarifs Première');
        print('Valeur du tarif première: ${_tarifPremiereController.text}');
        if (_tarifPremiereController.text.isEmpty) {
          throw Exception('Le tarif première est requis pour la catégorie Première');
        }
        movieData['tarif_premiere'] = int.tryParse(_tarifPremiereController.text);
        // Ajout des tarifs par défaut pour la catégorie Première
        movieData['tarif_enf_film'] = 0;
        movieData['tarif_adu_film'] = 0;
        movieData['prix'] = 0;
      } else if (_selectedCategoryId != null) {
        print('Validation des tarifs autre catégorie');
        if (_prixController.text.isEmpty) {
          throw Exception('Le tarif de la catégorie est requis');
        }
        movieData['prix'] = int.tryParse(_prixController.text);
        // Ajout des tarifs par défaut pour les autres catégories
        movieData['tarif_enf_film'] = 0;
        movieData['tarif_adu_film'] = 0;
        movieData['tarif_premiere'] = 0;
      }

      print('Données du film à envoyer: $movieData');

      if (_imageFile != null) {
        movieData['image_url'] = _imageFile;
      }

      if (widget.movieToEdit != null) {
        print('Mise à jour du film existant');
        final success = await _movieService.updateMovie(widget.movieToEdit!['id_film'], movieData);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Film modifié avec succès'), backgroundColor: Colors.green),
          );
          widget.onSuccess();
          Navigator.pop(context); // Fermer le formulaire après la modification
        } else {
          throw Exception('Échec de la modification du film');
        }
      } else {
        print('Création d\'un nouveau film');
        final movieId = await _movieService.addMovie(movieData);
        if (movieId > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Film ajouté avec succès'), backgroundColor: Colors.green),
          );
          widget.onSuccess();
          Navigator.pop(context); // Fermer le formulaire après l'ajout
          // Naviguer vers l'écran de programmation
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddProgrammeScreen(movieId: movieId),
            ),
          );
        } else {
          throw Exception('Échec de l\'ajout du film');
        }
      }
    } catch (e) {
      print('Erreur lors de la soumission: $e');
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
    return DropdownButtonFormField<int>(
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
          // Réinitialiser les contrôleurs de tarif lors du changement de catégorie
          _tarifEnfantController.clear();
          _tarifAdulteController.clear();
          _tarifPremiereController.clear();
          _prixController.clear();
        }
      },
      value: value,
      isExpanded: true,
      validator: validator,
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
        title: Text(
          'Programmation du film',
          style: TextStyle(color: Colors.white),
        ),
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