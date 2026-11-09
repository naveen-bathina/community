import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:legal_unity_network/core/config/app_config.dart';
import 'package:legal_unity_network/core/theme/app_theme.dart';
import 'package:legal_unity_network/shared/widgets/app_brand.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Union'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // Hero Branding Header
          Center(
            child: Column(
              children: [
                const AppLogo(size: 84),
                const SizedBox(height: 14),
                Text(
                  AppConfig.appName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Text(
                    AppConfig.appMotto,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown.shade800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppConfig.appTagline,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Chip(
                  avatar: const Icon(Icons.verified, size: 16, color: Colors.white),
                  label: const Text(
                    'Version ${AppConfig.appVersion} • Official Release',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Foundational Philosophy Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_stories, color: Colors.amber.shade800),
                      const SizedBox(width: 8),
                      const Text(
                        'Foundational Vision',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Text(
                    'Inspired by the constitutional ideals of Babasaheb Dr. B. R. Ambedkar, '
                    '${AppConfig.appName} is a non-partisan union dedicated to uniting, empowering, '
                    'and defending legal practitioners across all State Bar Councils in India.',
                    style: const TextStyle(fontSize: 14, height: 1.45),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '"Constitutional morality is not a natural sentiment. It has to be cultivated. '
                    'We must realize that our people have yet to learn it." — Dr. B. R. Ambedkar',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Core Pillars Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: AppTheme.primaryBlue),
                      SizedBox(width: 8),
                      Text(
                        'Core Pillars & Mission',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildPillarTile(
                    icon: Icons.badge_outlined,
                    title: 'Verified Advocate Fraternity',
                    subtitle:
                        'Only licensed advocates enrolled with recognized State Bar Councils are admitted after administrative credential verification.',
                  ),
                  _buildPillarTile(
                    icon: Icons.how_to_vote_outlined,
                    title: 'Democratic Self-Governance',
                    subtitle:
                        'Union leadership is decided through transparent, annual secret-ballot elections among all approved members.',
                  ),
                  _buildPillarTile(
                    icon: Icons.handshake_outlined,
                    title: 'Ethical Referrals & Collaboration',
                    subtitle:
                        'Seamless inter-jurisdictional referral coordination and mentorship without commercial intermediaries or advertising.',
                  ),
                  _buildPillarTile(
                    icon: Icons.gavel_outlined,
                    title: 'Legal Aid & Constitutional Defense',
                    subtitle:
                        'Promoting legal defense for marginalized communities and upholding fundamental rights guaranteed under the Constitution of India.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Union Secretariat & Contact
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.account_balance, color: AppTheme.primaryBlue),
                      SizedBox(width: 8),
                      Text(
                        'Secretariat & Contact Info',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.location_on_outlined, color: AppTheme.primaryBlue),
                    title: const Text('Headquarters & Secretariat'),
                    subtitle: const Text(AppConfig.secretariatAddress),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.email_outlined, color: AppTheme.primaryBlue),
                    title: const Text('Support Email'),
                    subtitle: const Text(AppConfig.supportEmail),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: 'Copy Email',
                      onPressed: () {
                        Clipboard.setData(const ClipboardData(text: AppConfig.supportEmail));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Support email copied!')),
                        );
                      },
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.phone_outlined, color: AppTheme.primaryBlue),
                    title: const Text('Toll-Free Helpline'),
                    subtitle: const Text(AppConfig.helplinePhone),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.language_outlined, color: AppTheme.primaryBlue),
                    title: const Text('Official Portal'),
                    subtitle: const Text(AppConfig.websiteUrl),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Open Source Licenses & System Information
          Card(
            child: ListTile(
              leading: const Icon(Icons.code_outlined, color: AppTheme.primaryBlue),
              title: const Text('Open Source Licenses & Attributions'),
              subtitle: const Text('View licenses for third-party libraries & software'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                showLicensePage(
                  context: context,
                  applicationName: AppConfig.appName,
                  applicationVersion: AppConfig.appVersion,
                  applicationIcon: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: AppLogo(size: 48),
                  ),
                  applicationLegalese:
                      '© 2026 ${AppConfig.organizationName}. All rights reserved.\n'
                      'Dedicated to the advancement of advocate solidarity and justice.',
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPillarTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textSecondaryLight,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
