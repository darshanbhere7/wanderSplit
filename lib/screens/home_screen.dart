import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'trip/add_trip_screen.dart';
import 'trip/trip_details_screen.dart';
import 'auth/login_screen.dart'; // Added import for LoginScreen

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
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('trips')
                  .where('participants', arrayContains: _currentUserId)
                  .orderBy('startDate', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  // Check for index error specifically
                  if (snapshot.error.toString().contains('index')) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!_indexError) {
                        setState(() {
                          _indexError = true;
                        });
                      }
                    });
                  }
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading trips',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.card_travel_rounded,
                            size: 64,
                            color: Colors.grey[400],
                          )
                              .animate(onPlay: (controller) => controller.repeat())
                              .shimmer(duration: 2.seconds),
                          const SizedBox(height: 16),
                          Text(
                            'No trips yet',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create a trip to start splitting expenses',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final trip = snapshot.data!.docs[index];
                      final data = trip.data() as Map<String, dynamic>;

                      // Add null checks for critical fields
                      final startDate = data['startDate'] != null
                          ? (data['startDate'] as Timestamp).toDate()
                          : DateTime.now();
                      final endDate = data['endDate'] != null
                          ? (data['endDate'] as Timestamp).toDate()
                          : DateTime.now();
                      final participants = data['participants'] != null
                          ? (data['participants'] as List).length
                          : 0;
                      final totalExpenses = data['totalExpenses'] != null
                          ? (data['totalExpenses'] as num)
                          : 0;

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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TripDetailsScreen(tripId: trip.id),
                                ),
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
                                          data['name'] as String? ?? 'Unnamed Trip',
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
                                          '\$${totalExpenses.toStringAsFixed(2)}',
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
                                        '${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d, y').format(endDate)}',
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
                                        '$participants participants',
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
                    childCount: snapshot.data!.docs.length,
                  ),
                );
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTripScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Trip'),
      )
          .animate()
          .scale(delay: 500.ms),
    );
  }
}