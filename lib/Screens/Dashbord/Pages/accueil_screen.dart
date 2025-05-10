import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../Core/helpers/bottom_nav_item.dart';
import 'ajout_screen.dart';
import 'profil_screen.dart';
import 'statistique_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0; // Default to the statistics screen
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Palette de couleurs raffinée
  final Color _primaryColor = Color(0xFF7F56D9);
  final Color _backgroundColor = Color(0xFFF8F9FC);
  final Color _activeIconColor = Colors.white;
  final Color _inactiveIconColor = Color(0xFFBDBDBD);
  final Color _navBarColor = Colors.white;
  final double _navBarIconSize = 28.0;

  static final List<Widget> _screens = <Widget>[
    StatsScreen(),
    AddScreen(),
    ProfileScreen2(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
      _animationController.forward().then((_) => _animationController.reverse());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        fontFamily: 'Inter',
        primaryColor: _primaryColor,
        colorScheme: ColorScheme.light(
          primary: _primaryColor,
        ),
        splashFactory: InkRipple.splashFactory,
      ),
      child: Scaffold(
        backgroundColor: _backgroundColor,
        extendBody: true,
        appBar: _buildAppBar(),
        body: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: 250),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: IndexedStack(
              key: ValueKey(_selectedIndex),
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 1,
      backgroundColor: Colors.white,
      centerTitle: true,
      title: Text(
        " Tableau de Bord ",
        style: GoogleFonts.montserrat(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _primaryColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Statistiques';
      case 1:
        return 'Ajouter';
      case 2:
        return 'Profil';
      default:
        return 'Tableau de Bord';
    }
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: _navBarColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          BottomNavItem(
            icon: Icons.bar_chart_rounded,
            label: 'Stats',
            index: 0,
            selectedIndex: _selectedIndex,
            onTap: _onItemTapped,
            activeColor: _primaryColor,
            inactiveColor: _inactiveIconColor,
            iconSize: _navBarIconSize,
          ),
          BottomNavItem(
            icon: Icons.add_circle_outline_rounded,
            label: 'Ajouter',
            index: 1,
            selectedIndex: _selectedIndex,
            onTap: _onItemTapped,
            activeColor: _primaryColor,
            inactiveColor: _inactiveIconColor,
            iconSize: _navBarIconSize,
          ),
          BottomNavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profil',
            index: 2,
            selectedIndex: _selectedIndex,
            onTap: _onItemTapped,
            activeColor: _primaryColor,
            inactiveColor: _inactiveIconColor,
            iconSize: _navBarIconSize,
          ),
        ],
      ),
    );
  }
}