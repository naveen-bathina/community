import 'package:flutter/material.dart';
import 'package:legal_unity_network/core/config/app_config.dart';
import 'package:legal_unity_network/core/theme/app_theme.dart';

class LegalScreen extends StatefulWidget {
  final int initialTabIndex;

  const LegalScreen({super.key, this.initialTabIndex = 0});

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legal & Compliance'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.description_outlined), text: 'Terms of Service'),
            Tab(icon: Icon(Icons.privacy_tip_outlined), text: 'Privacy Policy'),
            Tab(icon: Icon(Icons.gavel_outlined), text: 'BCI Disclaimer'),
            Tab(icon: Icon(Icons.handshake_outlined), text: 'Code of Conduct'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTermsOfServiceTab(),
          _buildPrivacyPolicyTab(),
          _buildBciDisclaimerTab(),
          _buildCodeOfConductTab(),
        ],
      ),
    );
  }

  Widget _buildTermsOfServiceTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeaderCard(
          title: 'Terms of Service & By-Laws',
          subtitle: 'Last updated: November 2026 • Effective for all Union Members',
          icon: Icons.description,
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          number: '1',
          title: 'Eligibility & Bar Enrollment Verification',
          content:
              'Membership in ${AppConfig.appName} is exclusively restricted to licensed Advocates '
              'holding a valid enrollment with a recognized State Bar Council under the Advocates Act, 1961. '
              'Every applicant must submit authentic enrollment credentials, which are verified by appointed Union Administrators '
              'prior to account approval.',
        ),
        _buildSectionCard(
          number: '2',
          title: 'Permissible Platform Use',
          content:
              'The platform is intended strictly for professional fraternal networking, knowledge exchange, '
              'case referrals, continuing legal education, and democratic participation in Union elections. '
              'Commercial solicitation, spamming, and non-legal advertising are strictly prohibited.',
        ),
        _buildSectionCard(
          number: '3',
          title: 'Account Integrity & Non-Transferability',
          content:
              'Your account represents your personal professional identity. Sharing login credentials, '
              'misrepresenting Bar qualifications, or impersonating another legal practitioner constitutes '
              'a material violation and grounds for permanent expulsion.',
        ),
        _buildSectionCard(
          number: '4',
          title: 'Democratic Governance & Voting',
          content:
              'All approved members are entitled to nominate candidates and vote in annual Union elections '
              'in accordance with the Union Constitution. Voting is conducted on a one-member, one-vote secret ballot principle.',
        ),
        _buildSectionCard(
          number: '5',
          title: 'Disciplinary Actions & Account Suspension',
          content:
              'The Union Executive Council reserves the right to suspend or revoke membership for violations of these Terms, '
              'breach of professional decorum, or revocation of license by any State Bar Council. '
              'Aggrieved members may appeal through the Grievance Redressal Committee.',
        ),
      ],
    );
  }

  Widget _buildPrivacyPolicyTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeaderCard(
          title: 'Advocate Data Privacy Policy',
          subtitle: 'Commitment to data confidentiality and advocate autonomy',
          icon: Icons.privacy_tip,
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          number: '1',
          title: 'Information We Collect',
          content:
              'We collect essential professional details necessary for verification and networking: '
              'full legal name, State Bar Council enrollment number, year of enrollment, mobile number, '
              'email address, practice areas, firm/chamber affiliation, and profile photo.',
        ),
        _buildSectionCard(
          number: '2',
          title: 'Member Directory Privacy Controls',
          content:
              'We respect your privacy. Members maintain full control in User Settings to show or hide their '
              'direct phone number and email address from the public Union directory while retaining access '
              'to internal messaging and referral inquiries.',
        ),
        _buildSectionCard(
          number: '3',
          title: 'Zero Commercial Monetization',
          content:
              '${AppConfig.appName} does NOT sell, rent, lease, or commercially trade advocate personal data '
              'to third parties, advertisers, or data aggregators under any circumstances.',
        ),
        _buildSectionCard(
          number: '4',
          title: 'Storage & Encryption Standards',
          content:
              'All credential records, join applications, and member communications are transmitted '
              'using SSL/TLS encryption and stored on secure cloud database clusters with row-level security policies.',
        ),
        _buildSectionCard(
          number: '5',
          title: 'Account Deletion & Data Retention',
          content:
              'Members may request full account deletion and removal of their profile data by contacting '
              'the Grievance Desk at ${AppConfig.grievanceEmail}.',
        ),
      ],
    );
  }

  Widget _buildBciDisclaimerTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeaderCard(
          title: 'Bar Council Regulatory Disclaimer',
          subtitle: 'Compliance with Bar Council of India Rules (Rule 36, Section IV)',
          icon: Icons.gavel,
          accentColor: Colors.deepPurple,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
                  const SizedBox(width: 8),
                  Text(
                    'Statutory Bar Council Compliance',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.brown.shade900,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                AppConfig.bciComplianceSummary,
                style: const TextStyle(fontSize: 13.5, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          number: '1',
          title: 'No Solicitation or Advertisement',
          content:
              'Under the Bar Council of India Rules, advocates in India are not permitted to advertise or solicit work. '
              'This application does not provide public client acquisition, paid featured listings, or commercial advertisement. '
              'It serves exclusively as an intra-advocate peer association tool for mutual knowledge and democratic governance.',
        ),
        _buildSectionCard(
          number: '2',
          title: 'No Attorney-Client Relationship',
          content:
              'No information published on this platform constitutes formal legal advice, nor does intra-member communication '
              'establish an attorney-client relationship between users and the Union or between members.',
        ),
        _buildSectionCard(
          number: '3',
          title: 'No Fee Sharing or Brokerage',
          content:
              'The Union does NOT charge any fee, referral commission, percentage, or brokerage on case referrals '
              'transacted between independent advocates. All professional arrangements are solely between the participating counsel.',
        ),
      ],
    );
  }

  Widget _buildCodeOfConductTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeaderCard(
          title: 'Advocate Code of Conduct & Ethics',
          subtitle: 'Professional decorum, equality, and fraternal standards',
          icon: Icons.handshake,
          accentColor: Colors.teal,
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          number: '1',
          title: 'Constitutional Morality & Equality',
          content:
              'Members are expected to uphold the preamble of the Constitution of India: Justice, Liberty, Equality, '
              'and Fraternity. Any form of discrimination based on caste, religion, gender, region, or background '
              'is strictly prohibited.',
        ),
        _buildSectionCard(
          number: '2',
          title: 'Professional Decorum & Respect for the Bench',
          content:
              'Discussions on the Community Wall and in Union forums must adhere to the highest standards of legal professionalism. '
              'Scandalizing the judiciary, defamatory remarks against colleague advocates, or unparliamentary language '
              'will result in immediate moderation and potential disciplinary action.',
        ),
        _buildSectionCard(
          number: '3',
          title: 'Support for Junior & First-Generation Advocates',
          content:
              'Senior advocates and established practitioners are encouraged to mentor junior advocates, '
              'first-generation lawyers, and colleagues from underprivileged backgrounds in the spirit of Dr. B.R. Ambedkar.',
        ),
        _buildSectionCard(
          number: '4',
          title: 'Protection of Client Confidentiality',
          content:
              'Advocates must never disclose confidential client information, privileged communications, or sensitive '
              'trial documents without appropriate redaction on community forums.',
        ),
      ],
    );
  }

  Widget _buildHeaderCard({
    required String title,
    required String subtitle,
    required IconData icon,
    Color accentColor = AppTheme.primaryBlue,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accentColor, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String number,
    required String title,
    required String content,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppTheme.primaryBlue,
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
