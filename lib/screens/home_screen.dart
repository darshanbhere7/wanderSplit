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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
        MaterialPageRoute(builder: (context) => const LoginScreen()),
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
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('WanderSplit'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _signOut,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Trips',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  if (_indexError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          const Text(
                            'Database index required',
                            style: TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _createIndex,
                            child: const Text('Create Index Now'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_currentUserId == null)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'Please sign in to view your trips',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            )
          else
            Consumer<MainProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (provider.error != null) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text(
                        provider.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }
                if (provider.trips.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'No trips yet',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _showAddTripDialog(),
                            child: const Text('Create New Trip'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final trip = provider.trips[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/trip_details',
                                arguments: trip,
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          trip.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '\$${trip.budget.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${DateFormat('MMM d').format(trip.startDate)} - ${trip.endDate != null ? DateFormat('MMM d, y').format(trip.endDate!) : 'No end date'}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.group_outlined,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${trip.members.length} participants',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 500.ms, delay: (index * 100).ms)
                          .slideX(begin: 0.2, end: 0);
                    },
                    childCount: provider.trips.length,
                  ),
                );
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTripDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Trip'),
      )
          .animate()
          .scale(delay: 500.ms),
    );
  }

  void _showAddTripDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTripDialog(
        onTripAdded: (trip) {
          // Optionally show a success message here
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trip created successfully!')),
          );
        },
      ),
    );
  }
}