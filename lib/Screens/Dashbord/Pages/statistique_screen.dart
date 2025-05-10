import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatsScreen extends StatelessWidget {
  final Map<String, int> ventesParType = {
    'Événement': 215,
    'Jeu': 180,
    'Cinéma': 250,
  };

  final List<String> topVendusEvenement = ['Concert VIP', 'Pièce de Théâtre', 'Festival'];
  final List<String> topVendusJeu = ['Tournoi Local', 'Soirée Jeux de Société', 'Escape Game'];
  final List<String> topVendusCinema = ['Blockbuster Actuel', 'Film Indépendant', 'Séance de Minuit'];

  final int totalClients = 645;

  // Couleurs de la palette
  final Color primaryViolet = Color(0xFF7F56D9);
  final Color accentOrange = Color(0xFFF97316);
  final Color lightGrey = Colors.grey[300]!;
  final Color whiteColor = Colors.white;
  final Color eventColor = Colors.blueAccent;
  final Color gameColor = Colors.greenAccent.shade700;
  final Color cinemaColor = Colors.orangeAccent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryViolet,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'Analyse des Ventes',
          style: GoogleFonts.montserrat(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              // Action pour rafraîchir les données
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          physics: ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: 8.0),
              _buildTicketTypeComparisonCard(context),
              SizedBox(height: 16.0),
              _buildTotalSoldByTypeCard(context),
              SizedBox(height: 16.0),
              _buildTopSellingByTypeCard(context, 'Événements', topVendusEvenement, eventColor),
              SizedBox(height: 16.0),
              _buildTopSellingByTypeCard(context, 'Jeux', topVendusJeu, gameColor),
              SizedBox(height: 16.0),
              _buildTopSellingByTypeCard(context, 'Cinéma', topVendusCinema, cinemaColor),
              SizedBox(height: 16.0),
              _buildTotalClientsCard(context),
              SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketTypeComparisonCard(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.pie_chart_rounded, color: primaryViolet, size: 24.0),
                SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    'Comparaison des Types de Tickets',
                    style: GoogleFonts.inter(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      color: primaryViolet,
                    ),
                    softWrap: true,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.0),
            // Wrap pour éviter les problèmes de dépassement
            Wrap(
              spacing: 16.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.spaceAround,
              children: ventesParType.entries.map((entry) {
                return _buildPieChartLegendItem(
                    _getColorForCategory(entry.key),
                    entry.key,
                    entry.value
                );
              }).toList(),
            ),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ventesParType.entries.map((entry) {
                return Flexible(
                  child: Column(
                    children: [
                      Container(
                        width: 30.0,
                        height: entry.value / 5.0,
                        color: _getColorForCategory(entry.key),
                      ),
                      SizedBox(height: 4.0),
                      Text('${entry.value}', style: TextStyle(fontSize: 12.0)),
                    ],
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 8.0),
            Text(
              'Distribution des ventes par catégorie de ticket',
              style: TextStyle(color: Colors.grey[600], fontSize: 12.0),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForCategory(String category) {
    switch (category) {
      case 'Événement':
        return eventColor;
      case 'Jeu':
        return gameColor;
      case 'Cinéma':
        return cinemaColor;
      default:
        return primaryViolet;
    }
  }

  Widget _buildPieChartLegendItem(Color color, String label, int value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.0,
              height: 12.0,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 4.0),
            Text(label, style: TextStyle(fontSize: 14.0)),
          ],
        ),
        Text('$value', style: TextStyle(fontSize: 12.0, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildTotalSoldByTypeCard(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.format_list_numbered_rounded, color: primaryViolet, size: 24.0),
                SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    'Total Vendus par Catégorie',
                    style: GoogleFonts.inter(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      color: primaryViolet,
                    ),
                    softWrap: true,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.0),
            _buildTotalSoldItem(context, 'Événements', ventesParType['Événement']!, eventColor),
            _buildTotalSoldItem(context, 'Jeux', ventesParType['Jeu']!, gameColor),
            _buildTotalSoldItem(context, 'Cinéma', ventesParType['Cinéma']!, cinemaColor),
            SizedBox(height: 8.0),
            Text(
              'Nombre total de tickets vendus pour chaque catégorie',
              style: TextStyle(color: Colors.grey[600], fontSize: 12.0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSoldItem(BuildContext context, String category, int total, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(Icons.label_outline, color: color, size: 16.0),
                SizedBox(width: 8.0),
                Flexible(
                  child: Text(
                    category,
                    style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w500),
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ),
          Text(
              '$total Tickets',
              style: TextStyle(fontSize: 15.0, color: color, fontWeight: FontWeight.bold)
          ),
        ],
      ),
    );
  }

  Widget _buildTopSellingByTypeCard(BuildContext context, String title, List<String> items, Color color) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.trending_up_rounded, color: color, size: 24.0),
                SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    'Top Vendus - $title',
                    style: GoogleFonts.inter(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      color: primaryViolet,
                    ),
                    softWrap: true,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Icon(Icons.label_outline, color: color, size: 16.0),
                    SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(fontSize: 14.0),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
            SizedBox(height: 8.0),
            Text(
              'Les articles les plus populaires dans la catégorie $title',
              style: TextStyle(color: Colors.grey[600], fontSize: 12.0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalClientsCard(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.people_rounded, color: accentOrange, size: 24.0),
                SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    'Total de Clients',
                    style: GoogleFonts.inter(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      color: primaryViolet,
                    ),
                    softWrap: true,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.0),
            Text(
              '$totalClients',
              style: GoogleFonts.montserrat(
                fontSize: 36.0,
                fontWeight: FontWeight.bold,
                color: primaryViolet,
              ),
            ),
            SizedBox(height: 8.0),
            Text(
              'Nombre total de clients enregistrés',
              style: TextStyle(color: Colors.grey[600], fontSize: 12.0),
            ),
          ],
        ),
      ),
    );
  }
}