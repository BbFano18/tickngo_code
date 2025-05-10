import 'package:TicknGo/Screens/interfaces/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'Tous';
  final List<NotificationItem> _notifications = [
    NotificationItem(
      title: "Nouvel événement",
      subtitle: "Concert de jazz ce weekend",
      time: "Il y a 2 heures",
      icon: Icons.event,
    ),
    NotificationItem(
      title: "Promotion",
      subtitle: "Réduction de 20% sur les billets de cinéma",
      time: "Hier",
      icon: Icons.local_offer,
      isRead: true,
    ),
    NotificationItem(
      title: "Rappel",
      subtitle: "Votre réservation pour 'Inception' expire bientôt",
      time: "Il y a 1 jour",
      icon: Icons.alarm,
    ),
  ];

  List<NotificationItem> get filteredNotifications {
    switch (_selectedFilter) {
      case 'Lu':
        return _notifications.where((n) => n.isRead).toList();
      case 'Non lu':
        return _notifications.where((n) => !n.isRead).toList();
      default:
        return _notifications;
    }
  }

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
              _buildFilterRow(),
              Expanded(child: _buildNotificationsList()),
            ],
          ),
        ),
      ),
    )
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
          "Notifications",
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
    const filters = ['Tous', 'Non lu', 'Lu'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 40,
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
                fontWeight: FontWeight.w500,
              ),
              onSelected: (selected) => setState(() => _selectedFilter = filters[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    if (filteredNotifications.isEmpty) {
      return _buildEmptyNotificationsView();
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredNotifications.length,
      itemBuilder: (context, index) {
        return _buildNotificationItem(filteredNotifications[index]);
      },
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    return Card(
      color: Colors.white.withOpacity(notification.isRead ? 0.1 : 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(notification.icon, color: Colors.amber, size: 32),
        title: Text(
          notification.title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          "${notification.subtitle}\n${notification.time}",
          style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.7)),
        ),
        trailing: !notification.isRead
            ? const CircleAvatar(radius: 6, backgroundColor: Colors.amber)
            : null,
        onTap: () => setState(() => notification.isRead = true),
      ),
    );
  }

  Widget _buildEmptyNotificationsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_off, size: 80, color: Colors.white54),
          const SizedBox(height: 16),
          Text(
            "Aucune notification ${_selectedFilter == 'Tous' ? '' : _selectedFilter}",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationItem {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  bool isRead;

  NotificationItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    this.isRead = false,
  });
}