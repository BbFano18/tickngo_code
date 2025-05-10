import 'package:flutter/material.dart';

import 'ajoutevent_screen.dart';
import 'ajoutfilm_screen.dart';
import 'ajoutjeux_screen.dart';

class AddScreen extends StatefulWidget {
  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> with SingleTickerProviderStateMixin{
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            'Ajouter un élément',
            style: TextStyle(
              color: Color(0xFF7F56D9),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          bottom: const TabBar(
            labelPadding: EdgeInsets.symmetric(horizontal: 5),
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              Tab(icon: Icon(Icons.movie_filter_rounded, size: 22), text: 'Films'),
              Tab(icon: Icon(Icons.sports_esports_rounded, size: 22), text: 'Jeux'),
              Tab(icon: Icon(Icons.event_available_rounded, size: 22), text: 'Événements'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            MovieDashboard(),
            GameDashboard(),
            EventDashboard(),
          ],
        ),
      ),
    );
  }
}

/*

  Widget _buildScrollableForm(Widget form) {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                spreadRadius: 2),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: form,
        ),
      ),
    );
  }
}

Widget _buildHeader(String text) {
  return Text(
    text,
    style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Color(0xFF7F56D9)),
    textAlign: TextAlign.center,
  );
}

Widget _buildTextField(String label, IconData icon) {
  return TextField(
      decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Color(0xFF7F56D9)),
  border: OutlineInputBorder(
  borderRadius: BorderRadius.circular(10),
  borderSide: BorderSide(color: Colors.grey.shade300)),
  focusedBorder: OutlineInputBorder(
  borderRadius: BorderRadius.circular(10),
  borderSide: BorderSide(color: Color(0xFF7F56D9), width: 2),
  ),
  ));
}

Widget _buildDescriptionField() {
  return TextField(
      maxLines: 4,
      decoration: InputDecoration(
      labelText: 'Description',
      alignLabelWithHint: true,
      prefixIcon: Icon(Icons.description, color: Color(0xFF7F56D9)),
  border: OutlineInputBorder(
  borderRadius: BorderRadius.circular(10),
  ),
  ));
}

Widget _buildDateField(String label) {
  return TextField(
      decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF7F56D9)),
  suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.grey),
  border: OutlineInputBorder(
  borderRadius: BorderRadius.circular(10)),
  ));
}

Widget _buildSubmitButton(String text) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF7F56D9),
      padding: EdgeInsets.symmetric(vertical: 15),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
    ),
    onPressed: () {},
    child: Text(
        text,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
  );
}*/
