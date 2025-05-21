import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../API/api_config.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class StatsScreen extends StatefulWidget {
  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool isLoading = true;
  Map<String, dynamic> statsData = {
    'ventesParType': {},
    'topVendus': {'evenement': [], 'jeu': [], 'cinema': []},
    'totalClients': 0,
    'revenusParMois': [],
    'tauxReservation': 0.0
  };

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    // Désactivation de l'affichage des erreurs
    return;
  }

  Future<void> _fetchStats() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/statistiques'),
        headers: {'Content-Type': 'application/json'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          statsData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Échec du chargement des statistiques');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);
      _showError('Erreur lors du chargement: ${e.toString().replaceAll(RegExp(r'^Exception: '), '')}');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFF7F56D9),
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'Statistiques',
          style: GoogleFonts.montserrat(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchStats,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchStats,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRevenueChart(),
              SizedBox(height: 20),
              _buildTicketTypeChart(),
              SizedBox(height: 20),
              _buildTopSellingSection(),
              SizedBox(height: 20),
              _buildPerformanceMetrics(),
              SizedBox(height: 70),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenus Mensuels',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7F56D9),
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                primaryYAxis: NumericAxis(
                  numberFormat: NumberFormat.compact(),
                  title: AxisTitle(text: 'Revenus (FCFA)'),
                ),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <CartesianSeries>[
                  ColumnSeries<Map<String, dynamic>, String>(
                    dataSource: List<Map<String, dynamic>>.from(
                        statsData['revenusParMois']),
                    xValueMapper: (Map<String, dynamic> data, _) =>
                    data['mois'] as String,
                    yValueMapper: (Map<String, dynamic> data, _) =>
                    data['montant'] as num,
                    name: 'Revenus',
                    color: Color(0xFF7F56D9),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketTypeChart() {
    final List<PieData> pieData = statsData['ventesParType']
        .entries
        .map<PieData>((entry) =>
        PieData(entry.key, (entry.value as num).toDouble()))
        .toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Répartition des Ventes',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7F56D9),
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: SfCircularChart(
                legend: Legend(isVisible: true, position: LegendPosition.bottom),
                series: <CircularSeries>[
                  PieSeries<PieData, String>(
                    dataSource: pieData,
                    xValueMapper: (PieData data, _) => data.category,
                    yValueMapper: (PieData data, _) => data.value,
                    dataLabelSettings: DataLabelSettings(isVisible: true),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSellingSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top des Ventes',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7F56D9),
              ),
            ),
            SizedBox(height: 20),
            _buildTopSellingList(
                'Événements', statsData['topVendus']['evenement'], Icons.event),
            _buildTopSellingList(
                'Jeux', statsData['topVendus']['jeu'], Icons.sports_esports),
            _buildTopSellingList(
                'Cinéma', statsData['topVendus']['cinema'], Icons.movie),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSellingList(
      String title, List<dynamic> items, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Color(0xFF7F56D9)),
            SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        ...items
            .map((item) => ListTile(
          leading: Icon(Icons.star, color: Colors.amber),
          title: Text(item['nom']),
          subtitle: Text('${item['ventes']} ventes'),
          trailing: Text('${item['revenu']} FCFA'),
        ))
            .toList(),
        Divider(),
      ],
    );
  }

  Widget _buildPerformanceMetrics() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Métriques de Performance',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7F56D9),
              ),
            ),
            SizedBox(height: 20),
            _buildMetricTile(
              'Clients Total',
              '${statsData['totalClients']}',
              Icons.people,
              Colors.blue,
            ),
            _buildMetricTile(
              'Taux de Réservation',
              '${(statsData['tauxReservation'] * 100).toStringAsFixed(1)}%',
              Icons.trending_up,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(
      String title, String value, IconData icon, Color color) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      trailing: Text(
        value,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class PieData {
  final String category;
  final double value;

  PieData(this.category, this.value);
}