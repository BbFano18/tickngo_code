import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../API/api_config.dart';
import '../interfaces/reservation_screen.dart';
import '../interfaces/splash_screen.dart';


class EventModel {
  final int idEvent;
  final String nomEvent;
  final String dateEvent;
  final String? image;
  final String logoUrl;
  final String lieuEvent;
  final int tarifStandard;
  final int tarifVIP;
  final int tarifVVIP;
  final Map<String, dynamic>? programme;

  EventModel({
    required this.idEvent,
    required this.nomEvent,
    required this.dateEvent,
    this.image,
    required this.logoUrl,
    required this.lieuEvent,
    required this.tarifStandard,
    required this.tarifVIP,
    required this.tarifVVIP,
    this.programme,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    // Extraire le chemin de l'image sans modification
    String logoPath = json['image'] as String? ?? '';

    return EventModel(
      idEvent: json['id_event'],
      nomEvent: json['nom_event'],
      dateEvent: json['date_event'],
      image: json['image'],
      logoUrl: logoPath,
      lieuEvent: json['lieu_event'],
      tarifStandard: json['tarif_standard'] ?? 0,
      tarifVIP: json['tarif_VIP'] ?? 0,
      tarifVVIP: json['tarif_VVIP'] ?? 0,
      programme: json['programme'],
    );
  }

  // Méthode pour obtenir l'URL du logo
  String getFullLogoUrl() {
    if (logoUrl.isEmpty) return '';
    if (logoUrl.startsWith('http')) return logoUrl;
    return '${ApiConfig.baseUrl2}storage/$logoUrl';
  }

  // Méthode pour l'image principal
  String getFullImageUrl() {
    if (image == null || image!.isEmpty) return '';
    if (image!.startsWith('http')) return image!;
    return '${ApiConfig.baseUrl2}storage/$image';
  }
}
class EventService {
  Future<List<EventModel>> getAllEvents() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl + ApiConfig.eventPath}'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> eventsData = responseData['data'];
        return eventsData.map((json) => EventModel.fromJson(json)).toList();
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
}

class EventsScreen extends StatefulWidget {
  @override
  _EventsScreenState createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<EventModel> filteredEvents = [];
  List<EventModel> allEvents = [];
  final EventService _eventService = EventService();

  @override
  void initState() {
    super.initState();
    _fetchEvents();
    _searchController.addListener(_filterEvents);
  }

  Future<void> _fetchEvents() async {
    try {
      final events = await _eventService.getAllEvents();
      if (mounted) {
        setState(() {
          allEvents = events;
          filteredEvents = allEvents;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterEvents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredEvents = allEvents.where((event) {
        return event.nomEvent.toLowerCase().contains(query) ||
            event.lieuEvent.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "TicknGo",
              style: GoogleFonts.montserrat(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 25),
                    child: Text(
                      'Événements Disponibles',
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    height: 50,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Rechercher un événement...',
                        hintStyle: GoogleFonts.montserrat(),
                        prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () => _searchController.clear(),
                        )
                            : null,
                      ),
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Expanded(
                    child: allEvents.isEmpty
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        childAspectRatio: 0.85,
                        mainAxisExtent: 300,
                      ),
                      itemCount: filteredEvents.length,
                      itemBuilder: (context, index) =>
                          _buildEventCard(context, filteredEvents[index]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, EventModel event) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          color: Colors.black.withOpacity(0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: event.getFullLogoUrl().isNotEmpty
                    ? Image.network(
                  event.getFullLogoUrl(),
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, trace) {
                    print("Erreur de chargement d'image: $err pour ${event.getFullLogoUrl()}");
                    return const Icon(Icons.event, color: Colors.white, size: 60);
                  },
                )
                    : Container(
                  color: Colors.grey.withOpacity(0.3),
                  width: double.infinity,
                  child: const Icon(Icons.event, color: Colors.white70, size: 60),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.nomEvent,
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(Icons.calendar_today, event.dateEvent),
                    _buildDetailRow(Icons.location_on, event.lieuEvent),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EventDetailsScreen(event: event),
                            ),
                          );
                        },
                        child: Text(
                          'Voir plus',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[300]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: Colors.grey[300],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class EventDetailsScreen extends StatelessWidget {
  final EventModel event;

  const EventDetailsScreen({super.key, required this.event});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "TicknGo",
              style: GoogleFonts.montserrat(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: event.getFullLogoUrl().isNotEmpty
                        ? Image.network(
                      event.getFullLogoUrl(),
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, trace) {
                        print("Erreur de chargement d'image dans détail: $err pour ${event.getFullLogoUrl()}");
                        return Container(
                          height: 250,
                          color: Colors.grey[800],
                          child: const Center(
                            child: Icon(Icons.event, color: Colors.white54, size: 80),
                          ),
                        );
                      },
                    )
                        : Container(
                      height: 250,
                      color: Colors.grey[800],
                      child: const Center(
                        child: Icon(Icons.event, color: Colors.white54, size: 80),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    event.nomEvent,
                    style: GoogleFonts.montserrat(
                      fontSize: 26,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildDetailItem(Icons.calendar_today, event.dateEvent),
                  _buildDetailItem(Icons.location_on, event.lieuEvent),
                  const SizedBox(height: 25),
                  _buildProgrammeSection(event.programme),
                  const SizedBox(height: 30),
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReservationScreen(
                                reservation: Reservation(
                                  eventTitle: event.nomEvent,
                                  eventDate: event.dateEvent,
                                  eventLocation: event.lieuEvent,
                                  eventTime: "Durée non spécifiée",
                                  ticketPrices: {
                                    "Adulte": 2000,
                                    "Enfant": 1000,
                                  },
                                  categoryPrices: {
                                    "Standard": 3000,
                                    "VIP": 15000,
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'Prendre un ticket',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildDetailItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.white),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgrammeSection(dynamic programme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Programme",
          style: GoogleFonts.montserrat(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        if (programme is Map<String, dynamic>)
          ..._parseProgramme(programme),
        if (programme is String)
          Text(programme,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.grey[300],
              height: 1.5,
            ),
          ),
      ],
    );
  }

  List<Widget> _parseProgramme(Map<String, dynamic> programme) {
    return programme.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• ',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            Expanded(
              child: Text(
                '${entry.key}: ${entry.value}',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: Colors.grey[300],
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}