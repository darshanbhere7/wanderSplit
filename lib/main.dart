import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/trip/add_trip_screen.dart';
import 'widgets/bottom_nav_bar.dart';
import 'services/card_info_service.dart';
import 'models/card_info_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'utils/constants.dart';
import 'providers/universal_currency_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => UniversalCurrencyProvider(),
      child: const WanderSplitApp(),
    ),
  );
}

class WanderSplitApp extends StatelessWidget {
  const WanderSplitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WanderSplit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B4EFF),
          primary: const Color(0xFF6B4EFF),
          secondary: const Color(0xFF00D1FF),
          tertiary: const Color(0xFFFF8A00),
          background: const Color(0xFFF8F9FE),
        ),
        useMaterial3: true,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xFFF8F9FE),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFF2D3142),
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6B4EFF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
      home: const MainNavScreen(),
    );
  }
}

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    SizedBox.shrink(), // Center Add button does not show a page
    const MessagesScreen(),
    const ProfileScreen(),
  ];

  void _onNavTap(int index) {
    if (index == 2) {
      // Open AddTripScreen as a modal
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => const Padding(
          padding: EdgeInsets.only(top: 24),
          child: AddTripScreen(),
        ),
      );
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _userName;
  String? _userEmail;
  bool _loading = true;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _userName = doc.data()?['name'] ?? '';
        _userEmail = doc.data()?['email'] ?? '';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyProvider = Provider.of<UniversalCurrencyProvider>(context);
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: theme.colorScheme.primary,
                tabs: const [
                  Tab(text: 'Account Info'),
                  Tab(text: 'Currency'),
                  Tab(text: 'Card Info'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Account Info Tab
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Name', style: theme.textTheme.bodySmall),
                          const SizedBox(height: 4),
                          Text(_userName ?? '', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 16),
                          Text('Email', style: theme.textTheme.bodySmall),
                          const SizedBox(height: 4),
                          Text(_userEmail ?? '', style: theme.textTheme.titleMedium),
                        ],
                      ),
                    ),
                    // Universal Currency Tab
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Universal Currency', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: currencyProvider.currency,
                            items: AppConstants.currencySymbols.keys.map((code) {
                              return DropdownMenuItem(
                                value: code,
                                child: Text('${AppConstants.getCurrencySymbol(code)} $code'),
                              );
                            }).toList(),
                            onChanged: (val) async {
                              if (val != null) {
                                await currencyProvider.setCurrency(val);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Currency updated to ${AppConstants.getCurrencySymbol(val)} ($val)'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              }
                            },
                            decoration: const InputDecoration(
                              labelText: 'Select Currency',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Card Info Tab
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: CardInfoExpandable(),
                    ),
                  ],
                ),
              ),
            ],
          );
  }
}

class CardInfoExpandable extends StatefulWidget {
  @override
  State<CardInfoExpandable> createState() => _CardInfoExpandableState();
}

class _CardInfoExpandableState extends State<CardInfoExpandable> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: const Text('Card Details'),
          trailing: IconButton(
            icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
            onPressed: () => setState(() => _expanded = !_expanded),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: CardDetailsForm(),
        ),
      ],
    );
  }
}

class CardDetailsForm extends StatefulWidget {
  @override
  State<CardDetailsForm> createState() => _CardDetailsFormState();
}

class _CardDetailsFormState extends State<CardDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _holderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _balanceController = TextEditingController();
  bool _loading = false;
  CardInfoService _service = CardInfoService();

  @override
  void initState() {
    super.initState();
    _loadCardInfo();
  }

  Future<void> _loadCardInfo() async {
    final card = await _service.getCardInfo();
    if (card != null) {
      _numberController.text = card.cardNumber;
      _holderController.text = card.cardHolder;
      _expiryController.text = card.expiryDate;
      _balanceController.text = card.balance.toStringAsFixed(2);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final card = CardInfo(
      cardNumber: _numberController.text.trim(),
      cardHolder: _holderController.text.trim(),
      expiryDate: _expiryController.text.trim(),
      balance: double.tryParse(_balanceController.text.trim()) ?? 0.0,
    );
    await _service.setCardInfo(card);
    setState(() => _loading = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Card info saved!'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Card Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(labelText: 'Card Number'),
                keyboardType: TextInputType.number,
                maxLength: 16,
                validator: (v) => v == null || v.length < 12 ? 'Enter a valid card number' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _holderController,
                decoration: const InputDecoration(labelText: 'Cardholder Name'),
                validator: (v) => v == null || v.isEmpty ? 'Enter cardholder name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _expiryController,
                decoration: const InputDecoration(labelText: 'Expiry Date (MM/YY)'),
                maxLength: 5,
                validator: (v) => v == null || !RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$').hasMatch(v) ? 'Enter MM/YY' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _balanceController,
                decoration: const InputDecoration(labelText: 'Balance'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v == null || double.tryParse(v) == null ? 'Enter a valid balance' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading ? const CircularProgressIndicator() : const Text('Save Card Info'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _numberController.dispose();
    _holderController.dispose();
    _expiryController.dispose();
    _balanceController.dispose();
    super.dispose();
  }
}

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Search Coming Soon',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Messages Coming Soon',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
