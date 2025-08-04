import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/custom_app_bar.dart';

class IntroductionScreen extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const IntroductionScreen({
    Key? key,
    required this.isDarkMode,
    required this.onThemeToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Welcome to WanderSplit',
        isDarkMode: isDarkMode,
        onThemeToggle: onThemeToggle,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.12),
              theme.colorScheme.secondary.withOpacity(0.10),
              theme.colorScheme.background,
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Logo and Title
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.card_travel,
                      size: 80,
                      color: theme.colorScheme.primary,
                    )
                    .animate()
                    .scale(duration: 600.ms)
                    .fadeIn(),
                    const SizedBox(height: 16),
                    Text(
                      'WanderSplit',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 200.ms)
                    .slideY(begin: -0.2, end: 0),
                    const SizedBox(height: 8),
                    Text(
                      'Split expenses with friends and family',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 300.ms)
                    .slideY(begin: 0.2, end: 0),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Features Section
              Text(
                'Features',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              )
              .animate()
              .fadeIn(duration: 600.ms, delay: 400.ms)
              .slideX(begin: -0.2, end: 0),
              const SizedBox(height: 24),

              // Feature Cards
              _buildFeatureCard(
                context,
                icon: Icons.group,
                title: 'Group Expenses',
                description: 'Create trips and add members to split expenses with friends and family.',
                delay: 500,
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                context,
                icon: Icons.receipt_long,
                title: 'Track Expenses',
                description: 'Add and categorize expenses, upload receipts, and keep track of who paid for what.',
                delay: 600,
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                context,
                icon: Icons.account_balance_wallet,
                title: 'Settle Up',
                description: 'Automatically calculate who owes whom and settle up with ease.',
                delay: 700,
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                context,
                icon: Icons.analytics,
                title: 'Expense Analytics',
                description: 'View detailed breakdowns of expenses by category and member.',
                delay: 800,
              ),
              const SizedBox(height: 48),

              // Get Started Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Get Started'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 600.ms, delay: 900.ms)
              .slideY(begin: 0.2, end: 0),
              const SizedBox(height: 48),

              // Contact Us Section
              Text(
                'Contact Us',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              )
              .animate()
              .fadeIn(duration: 600.ms, delay: 1000.ms)
              .slideX(begin: -0.2, end: 0),
              const SizedBox(height: 24),

              // Contact Cards
              _buildContactCard(
                context,
                icon: Icons.email,
                title: 'Email',
                description: 'support@wandersplit.com',
                onTap: () => _launchUrl('mailto:support@wandersplit.com'),
                delay: 1100,
              ),
              const SizedBox(height: 16),
              _buildContactCard(
                context,
                icon: Icons.phone,
                title: 'Phone',
                description: '+1 (555) 123-4567',
                onTap: () => _launchUrl('tel:+15551234567'),
                delay: 1200,
              ),
              const SizedBox(height: 16),
              _buildContactCard(
                context,
                icon: Icons.location_on,
                title: 'Address',
                description: 'SPIT, Andheri, Mumbai',
                onTap: () => _launchUrl('https://maps.google.com/?q=SPIT+Andheri+Mumbai'),
                delay: 1300,
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required int delay,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.13),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 36,
              ),
            )
            .animate()
            .scale(duration: 300.ms, delay: (delay + 100).ms),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: (delay + 200).ms)
                  .slideX(begin: 0.2, end: 0),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: (delay + 300).ms)
                  .slideX(begin: 0.2, end: 0),
                ],
              ),
            ),
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 600.ms, delay: delay.ms)
    .slideX(begin: -0.2, end: 0);
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    required int delay,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
              )
              .animate()
              .scale(duration: 300.ms, delay: (delay + 100).ms),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: (delay + 200).ms)
                    .slideX(begin: 0.2, end: 0),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: (delay + 300).ms)
                    .slideX(begin: 0.2, end: 0),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 600.ms, delay: delay.ms)
    .slideX(begin: -0.2, end: 0);
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}