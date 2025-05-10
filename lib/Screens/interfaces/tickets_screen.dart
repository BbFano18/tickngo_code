import 'package:TicknGo/Screens/interfaces/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  _TicketsScreenState createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  String _selectedFilter = 'Tous';
  final List<Map<String, dynamic>> _tickets = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildAppBar(),
                const SizedBox(height: 20),
                _buildFilterRow(),
                const SizedBox(height: 20),
                Expanded(
                  child: _buildTicketsList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        Text(
          "Mes Tickets",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildFilterRow() {
    const filters = ['Tous', 'Cinéma', 'Jeu', 'Événement'];
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return ChoiceChip(
            label: Text(filters[index]),
            selected: _selectedFilter == filters[index],
            selectedColor: Colors.white.withOpacity(0.2),
            labelStyle: GoogleFonts.poppins(
              color: _selectedFilter == filters[index]
                  ? Colors.grey
                  : Colors.black,
            ),
            onSelected: (selected) {
              setState(() => _selectedFilter = filters[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildTicketsList() {
    final filteredTickets = _selectedFilter == 'Tous'
        ? _tickets
        : _tickets.where((t) => t['type'] == _selectedFilter).toList();

    if (filteredTickets.isEmpty) {
      return Center(
        child: Text(
          "Aucun ticket disponible pour le moment",
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: filteredTickets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 15),
      itemBuilder: (context, index) {
        final ticket = filteredTickets[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket['titre'],
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Expire le ${ticket['expiration']}',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
