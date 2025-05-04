import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'trip/add_trip_screen.dart';
import 'trip/trip_details_screen.dart';
import 'auth/login_screen.dart'; // Added import for LoginScreen
import '../services/trip_service.dart';
import '../services/card_info_service.dart';
import '../models/card_info_model.dart';
import '../utils/constants.dart';
import 'package:provider/provider.dart';
import '../providers/universal_currency_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _tripService = TripService();
  final CardInfoService _cardInfoService = CardInfoService();
  String? _currentUserId;
  String? _userName;
  String? _userAvatarUrl;
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
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        setState(() {
          _currentUserId = user.uid;
          _userName = userDoc.data()?['name'] ?? 'User';
          _userAvatarUrl = userDoc.data()?['avatarUrl'];
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

  Stream<QuerySnapshot> get _tripsStream =>
      _firestore
          .collection('trips')
          .where('participants', arrayContains: _auth.currentUser?.uid)
          .orderBy('startDate', descending: true)
          .snapshots();

  Future<void> _deleteTrip(String tripId, String tripName) async {
    try {
      await _tripService.deleteTrip(tripId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting trip: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool?> _showDeleteTripDialog(String tripId, String tripName) async {
    if (!mounted) return false;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: Text('Are you sure you want to delete "$tripName"? This will also delete all associated expenses.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      await _deleteTrip(tripId, tripName);
    }
    return result;
  }

  String _maskCardNumber(String number) {
    if (number.length < 4) return '****';
    return '**** **** **** ${number.substring(number.length - 4)}';
  }

  String _maskCardHolder(String name) {
    if (name.isEmpty) return '****';
    return name[0] + '*' * (name.length - 1);
  }

  String _maskExpiry(String expiry) {
    if (expiry.length < 2) return '**/**';
    return '**/**'; // Always mask expiry for privacy
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final universalCurrency = Provider.of<UniversalCurrencyProvider>(context).currency;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.10),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundImage: _userAvatarUrl != null
                                  ? NetworkImage(_userAvatarUrl!)
                                  : null,
                              child: _userAvatarUrl == null
                                  ? Text(
                                      _userName != null && _userName!.isNotEmpty
                                          ? _userName![0]
                                          : 'U',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                              backgroundColor: theme.colorScheme.secondary,
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome,',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  Text(
                                    _userName ?? 'User',
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1, end: 0),
                    ),
                  ),
                  // Card Info Section (replaces analytics)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: StreamBuilder<CardInfo?>(
                        stream: _cardInfoService.cardInfoStream(),
                        builder: (context, snapshot) {
                          final card = snapshot.data;
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.secondary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(0.12),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: card == null
                                ? Center(
                                    child: Text(
                                      'No card info. Add your card in Profile.',
                                      style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppConstants.formatAmount(card.balance, currencyCode: universalCurrency),
                                        style: theme.textTheme.headlineLarge?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 32,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _maskCardNumber(card.cardNumber),
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          color: Colors.white,
                                          letterSpacing: 2,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _maskCardHolder(card.cardHolder),
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: Colors.white70,
                                            ),
                                          ),
                                          Text(
                                            _maskExpiry(card.expiryDate),
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Trips Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Text(
                        'Your Trips',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: StreamBuilder<QuerySnapshot>(
                      stream: _tripsStream,
                      builder: (context, snapshot) {
                        if (_isLoading) {
                          return const SliverFillRemaining(
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (snapshot.hasError) {
                          return SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'Error loading trips: ${snapshot.error}',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Center(
                                child: Text(
                                  'No trips yet. Tap the + button to add your first trip!',
                                  style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[500]),
                                ),
                              ),
                            ),
                          );
                        }
                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final trip = snapshot.data!.docs[index];
                              final data = trip.data() as Map<String, dynamic>;
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
                              return Dismissible(
                                key: Key(trip.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 16),
                                  color: Colors.red,
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                confirmDismiss: (direction) async {
                                  return await _showDeleteTripDialog(
                                    trip.id,
                                    data['name'] as String,
                                  );
                                },
                                child: Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
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
                                    borderRadius: BorderRadius.circular(20),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  data['name'] as String? ?? 'Unnamed Trip',
                                                  style: theme.textTheme.titleLarge?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.primary.withOpacity(0.08),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  AppConstants.formatAmount(totalExpenses.toDouble(), currencyCode: universalCurrency),
                                                  style: TextStyle(
                                                    color: theme.colorScheme.primary,
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
                                                style: theme.textTheme.bodyMedium?.copyWith(
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
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ).animate().fadeIn(duration: 400.ms, delay: (index * 80).ms).slideY(begin: 0.1, end: 0),
                              );
                            },
                            childCount: snapshot.data!.docs.length,
                          ),
                        );
                      },
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
      ),
    );
  }
}