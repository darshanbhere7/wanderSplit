import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'trip/add_trip_screen.dart';
import 'trip/trip_details_screen.dart';
import 'auth/login_screen.dart'; // Added import for LoginScreen
import 'package:provider/provider.dart';
import '../providers/main_provider.dart';
import '../models/trip_model.dart';
import '../widgets/add_trip_dialog.dart';
import '../widgets/custom_app_bar.dart';
import 'profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String? _currentUserId;
  bool _isLoading = true;
  String? _error;
  bool _indexError = false;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        setState(() {
          _currentUserId = user.uid;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = 'User not authenticated';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error fetching user: ${e.toString()}';
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      // Navigate to LoginScreen and clear navigation stack
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen(
          isDarkMode: widget.isDarkMode,
          onThemeToggle: widget.onThemeToggle,
        )),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      setState(() {
        _error = 'Error signing out: ${e.toString()}';
      });
    }
  }

  Future<void> _createIndex() async {
    // Replace with your actual index creation URL from the error message
    const indexUrl = 'https://console.firebase.google.com/v1/r/project/your-project-id/firestore/indexes?create_composite=...';

    try {
      if (await canLaunchUrl(Uri.parse(indexUrl))) {
        await launchUrl(Uri.parse(indexUrl));
      } else {
        setState(() {
          _error = 'Could not launch URL';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error launching URL: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mainProvider = context.watch<MainProvider>();
    final trips = mainProvider.trips;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'My Trips',
        isDarkMode: widget.isDarkMode,
        onThemeToggle: widget.onThemeToggle,
        onLogout: _signOut,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_rounded),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.10),
              theme.colorScheme.secondary.withOpacity(0.08),
              theme.colorScheme.background,
              Colors.white,
            ],
          ),
        ),
        child: trips.isEmpty
            ? Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.card_travel,
                        size: 80,
                        color: theme.colorScheme.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No trips yet',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showAddTripDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Create Trip'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: trips.length,
                itemBuilder: (context, index) {
                  final trip = trips[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    shadowColor: theme.colorScheme.primary.withOpacity(0.18),
                    child: InkWell(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/trip_details',
                          arguments: trip,
                        );
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withOpacity(0.13),
                              theme.colorScheme.secondary.withOpacity(0.10),
                              Colors.white.withOpacity(0.95),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                                  radius: 28,
                                  child: Icon(
                                    Icons.card_travel,
                                    color: theme.colorScheme.primary,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        trip.name,
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        trip.description,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              children: [
                                if (trip.location != null && trip.location!.isNotEmpty)
                                  _buildInfoChip(
                                    icon: Icons.location_on,
                                    label: trip.location!,
                                    theme: theme,
                                  ),
                                _buildInfoChip(
                                  icon: Icons.calendar_today,
                                  label: '${trip.startDate.year}-${trip.startDate.month.toString().padLeft(2, '0')}-${trip.startDate.day.toString().padLeft(2, '0')}',
                                  theme: theme,
                                ),
                                if (trip.endDate != null)
                                  _buildInfoChip(
                                    icon: Icons.calendar_today,
                                    label: '${trip.endDate!.year}-${trip.endDate!.month.toString().padLeft(2, '0')}-${trip.endDate!.day.toString().padLeft(2, '0')}',
                                    theme: theme,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTripDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Create Trip'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required ThemeData theme,
  }) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
      labelStyle: TextStyle(color: theme.colorScheme.onSurface),
    )
    .animate()
    .scale(duration: 300.ms);
  }

  void _showAddTripDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddTripDialog(
        onTripAdded: (trip) {
          context.read<MainProvider>().addTrip(trip);
        },
      ),
    );
  }
}