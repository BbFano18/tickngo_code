import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../Services/ajoutevent_service.dart';
//Affichage des evenements
class EventDashboard extends StatefulWidget {
  const EventDashboard({Key? key}) : super(key: key);

  @override
  _EventDashboardState createState() => _EventDashboardState();
}

class _EventDashboardState extends State<EventDashboard> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _events = [];
  final EventService _eventService = EventService();
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final userId = await _getUserId();
      final List<Map<String, dynamic>> events = await _eventService.fetchEvents(userId);
      setState(() {
        _events = events;
      });
    } catch (e) {
      print('Erreur lors du chargement des événements: $e');
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

  void _showAddEventForm() {
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
                    child: AddEventForm(
                      centreId: _userId!,
                      onSuccess: () {  // Correction: onSuccess au lieu de onEventAdded
                        Navigator.pop(context);
                        _loadEvents();
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
            'Ajouter un Événement',
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

  void _deleteEvent(int id) async {
    bool confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer cet événement?'),
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
      final success = await _eventService.deleteEvent(id);
      final message = success ? 'Événement supprimé avec succès' : 'Échec de la suppression';
      final color = success ? Colors.green : Colors.red;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
      if (success) _loadEvents();
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

  void _editEvent(Map<String, dynamic> event) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('En cours de conception ... ')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_events.isEmpty == true)
          ? _buildEmptyState()
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Ajouter un événement'),
              onPressed: _showAddEventForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
          Expanded(child: _buildEventList()),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Aucun événement disponible',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Cliquez sur "Ajouter un événement" pour commencer',
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.add, color: Colors.white),
            label: Text('Ajouter un événement'),
            onPressed: _showAddEventForm,
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

  Widget _buildEventList() {
    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: 80.0),
        children: [
          ..._events.map((event) => _buildEventCard(event)).toList(),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.all(12),
        leading: _buildEventImage(event['image_url']),
        title: Text(event['nom_event'] ?? 'Sans titre', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text('Lieu: ${event['lieu_event'] ?? 'N/A'}'),
            Text('Date: ${event['date_event'] ?? 'N/A'}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: Icon(Icons.edit, color: Colors.blue), onPressed: () => _editEvent(event)),
            IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteEvent(event['id_event'])),
          ],
        ),
      ),
    );
  }

  Widget _buildEventImage(String? url) {
    if (url == null) {
      return Container(
        width: 60,
        height: 80,
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
        child: Icon(Icons.event, color: Colors.grey[600]),
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
//Formulaire d'ajout
class AddEventForm extends StatefulWidget {
  final Function onSuccess;
  final int centreId;

  AddEventForm({required this.onSuccess, required this.centreId});

  @override
  _AddEventFormState createState() => _AddEventFormState();
}

class _AddEventFormState extends State<AddEventForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lieuController = TextEditingController();
  final _tarifStandardController = TextEditingController();
  final _tarifVIPController = TextEditingController();
  final _tarifVVIPController = TextEditingController();
  final EventService _eventService = EventService();

  final _imagePicker = ImagePicker();

  bool _hasTarifStandard = true;
  bool _hasTarifVIP = false;
  bool _hasTarifVVIP = false;
  bool _isLoading = false;

  DateTime? _selectedDate;
  File? _imageFile;
  String? _imagePath;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
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

  void _submitForm(BuildContext ctx) async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      _showErrorSnackBar('Veuillez sélectionner une date pour l\'événement');
      return;
    }

    if (_hasTarifStandard && _tarifStandardController.text.isEmpty) {
      _showErrorSnackBar('Veuillez entrer un tarif standard');
      return;
    }

    if (_hasTarifVIP && _tarifVIPController.text.isEmpty) {
      _showErrorSnackBar('Veuillez entrer un tarif VIP');
      return;
    }

    if (_hasTarifVVIP && _tarifVVIPController.text.isEmpty) {
      _showErrorSnackBar('Veuillez entrer un tarif VVIP');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final event = {
        'id_centre': widget.centreId,
        'nom_event': _nameController.text,
        'date_event': _selectedDate!.toIso8601String(),
        'lieu_event': _lieuController.text,
        'tarif_standard': _hasTarifStandard ? int.parse(_tarifStandardController.text) : 0,
        'tarif_VIP': _hasTarifVIP ? int.parse(_tarifVIPController.text) : 0,
        'tarif_VVIP': _hasTarifVVIP ? int.parse(_tarifVVIPController.text) : null,
        'image': _imagePath,
      };

      final eventId = await _eventService.addEvent(event);

      if (eventId > 0) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('Événement ajouté avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(ctx).pop();
        //widget.onSuccess();
      } else {
        _showErrorSnackBar('Échec de l\'ajout de l\'événement');
      }
    } catch (e) {
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
            // Section Image
            _buildImagePicker(),
            SizedBox(height: 20),

            // Section Informations générales
            _buildSectionTitle('Informations générales'),
            _buildTextField(
              controller: _nameController,
              label: 'Nom de l\'événement',
              icon: Icons.event_note,
              isRequired: true,
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: _lieuController,
              label: 'Lieu',
              icon: Icons.location_on,
              isRequired: true,
            ),
            SizedBox(height: 16),
            _buildDatePicker(),
            SizedBox(height: 20),

            // Section Tarifs
            _buildSectionTitle('Configuration des tarifs'),
            _buildTarifSection(
              label: 'Tarif Standard',
              isSelected: _hasTarifStandard,
              onChanged: (val) => setState(() => _hasTarifStandard = val!),
              controller: _tarifStandardController,
            ),
            _buildTarifSection(
              label: 'Tarif VIP',
              isSelected: _hasTarifVIP,
              onChanged: (val) => setState(() => _hasTarifVIP = val!),
              controller: _tarifVIPController,
            ),
            _buildTarifSection(
              label: 'Tarif VVIP',
              isSelected: _hasTarifVVIP,
              onChanged: (val) => setState(() => _hasTarifVVIP = val!),
              controller: _tarifVVIPController,
            ),
            SizedBox(height: 32),

            // Bouton de soumission
            _buildSubmitButton(context),
            SizedBox(height: 20),
          ],
        ),
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
        child: _imageFile != null ?
        ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Image.file(
            _imageFile!,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        ) :
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey[600]),
            SizedBox(height: 8),
            Text(
              'Ajouter une image',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.deepPurple, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'Ce champ est requis';
        }
        return null;
      },
    );
  }

  Widget _buildDatePicker() {
    final formattedDate = _selectedDate != null
        ? DateFormat.yMMMMd().format(_selectedDate!)
        : 'Sélectionner une date';

    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.deepPurple),
            SizedBox(width: 12),
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 16,
                color: _selectedDate != null ? Colors.black : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTarifSection({
    required String label,
    required bool isSelected,
    required Function(bool?) onChanged,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: onChanged,
              activeColor: Colors.deepPurple,
            ),
            Text(label, style: TextStyle(fontSize: 16)),
          ],
        ),
        if (isSelected)
          Padding(
            padding: const EdgeInsets.only(left: 32.0, right: 0, bottom: 12.0),
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Montant (FCFA)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[400]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                ),
                suffixText: 'FCFA',
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext c) {
    return ElevatedButton(
      onPressed: () {
        if (_isLoading) return;
        _submitForm(c);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: _isLoading
          ? CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
          : Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'Créer l\'événement',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}