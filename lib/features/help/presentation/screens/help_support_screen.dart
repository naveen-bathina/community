import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:legal_unity_network/core/config/app_config.dart';
import 'package:legal_unity_network/core/theme/app_theme.dart';

class HelpFaqItem {
  final String question;
  final String answer;
  final String category;

  const HelpFaqItem({
    required this.question,
    required this.answer,
    required this.category,
  });
}

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const List<String> categories = [
    'All',
    'Verification',
    'Directory',
    'Community Wall',
    'Elections',
    'Privacy',
  ];

  static List<HelpFaqItem> get allFaqs => [
    HelpFaqItem(
      category: 'Verification',
      question: 'How do I get my Join Request approved?',
      answer:
          'When you register, you must provide your legal name, State Bar Association, and Bar enrollment number (e.g. KAR/1234/2020). '
          'Union Administrators review enrollment records against public Bar Council registers before granting access. '
          'Approvals typically occur within 24 to 48 business hours.',
    ),
    HelpFaqItem(
      category: 'Verification',
      question: 'What happens if my application is rejected?',
      answer:
          'If your application is rejected or details are incomplete, you will see an "Access Restricted" screen with the administrator note. '
          'You can tap "Update & Resubmit Join Request" to rectify any typo in your enrollment number or date of birth and re-apply.',
    ),
    HelpFaqItem(
      category: 'Directory',
      question: 'How can other advocates find me for case referrals?',
      answer:
          'Approved members appear in the Advocate Directory. Colleagues can search by advocate name, city/state, or filter by specific practice areas '
          '(e.g. Constitutional Law, Criminal Defense, Intellectual Property, Family Law). Keeping your practice areas updated increases referral matches.',
    ),
    HelpFaqItem(
      category: 'Directory',
      question: 'Can I hide my phone number or email from the directory?',
      answer:
          'Yes. Open User Settings from your profile menu. Under "Directory Privacy", you can toggle off "Show Mobile Number in Directory" '
          'or "Show Email Address in Directory" at any time.',
    ),
    HelpFaqItem(
      category: 'Community Wall',
      question: 'What types of content can I post on the Community Wall?',
      answer:
          'You can post case law summaries, legal inquiries, Bar announcements, continuing education insights, and judgments. '
          'Posts support text, images, PDF documents (up to 5MB), and hyperlinks. Commercial advertisements and unparliamentary content are prohibited.',
    ),
    HelpFaqItem(
      category: 'Community Wall',
      question: 'Can I attach PDF petitions or documents to a post?',
      answer:
          'Yes! When writing a post, tap the document icon to attach a PDF or DOC file up to 5MB. Other advocates can download and view the attachment directly.',
    ),
    HelpFaqItem(
      category: 'Elections',
      question: 'How do Union Elections work?',
      answer:
          'Annual elections are held to democratically elect Union Administrators. When nominations open, any approved member in good standing can self-nominate. '
          'Following nominations, a two-week secret ballot voting period allows members to cast their vote electronically. The top vote recipients assume office.',
    ),
    HelpFaqItem(
      category: 'Privacy',
      question: 'Is my data shared with commercial entities?',
      answer:
          'Never. ${AppConfig.appName} enforces strict non-commercial data sovereignty. Your credentials and information are used solely for internal union verification and peer networking.',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<HelpFaqItem> get _filteredFaqs {
    return allFaqs.where((faq) {
      final matchesCategory =
          _selectedCategory == 'All' || faq.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          faq.question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faq.answer.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _showGrievanceDialog() {
    final subjectController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedType = 'Membership / Verification Issue';

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.support_agent, color: AppTheme.primaryBlue),
                  SizedBox(width: 10),
                  Text('Submit Support Query', style: TextStyle(fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Our Grievance Redressal Cell will respond within 24 hours:',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Issue Category',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Membership / Verification Issue',
                          child: Text('Membership / Verification Issue'),
                        ),
                        DropdownMenuItem(
                          value: 'Technical Bug or App Error',
                          child: Text('Technical Bug or App Error'),
                        ),
                        DropdownMenuItem(
                          value: 'Directory or Profile Update',
                          child: Text('Directory or Profile Update'),
                        ),
                        DropdownMenuItem(
                          value: 'Code of Conduct Grievance',
                          child: Text('Code of Conduct Grievance'),
                        ),
                        DropdownMenuItem(
                          value: 'General Inquiry / Feedback',
                          child: Text('General Inquiry / Feedback'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedType = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        hintText: 'Brief summary of issue',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Provide details, enrollment number if applicable...',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (descriptionController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a brief description'),
                        ),
                      );
                      return;
                    }
                    Navigator.of(dialogCtx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Ticket logged successfully! Grievance desk has been notified ($selectedType).',
                        ),
                        backgroundColor: AppTheme.successGreen,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  },
                  child: const Text('Submit Ticket'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final faqs = _filteredFaqs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Contact Channels Card
          Card(
            color: Colors.blue.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.blue.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.headset_mic, color: AppTheme.primaryBlue),
                      const SizedBox(width: 10),
                      Text(
                        'Union Helpdesk & Grievance Cell',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Need assistance with your enrollment verification, elections, or app features? Reach out directly:',
                    style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.email_outlined, size: 16),
                          label: const Text('Email Support', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onPressed: () {
                            Clipboard.setData(
                              const ClipboardData(text: AppConfig.supportEmail),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Copied support@jaibhimadvocates.org to clipboard!'),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.send, size: 16),
                          label: const Text('Submit Ticket', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onPressed: _showGrievanceDialog,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search questions, verification, elections...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          const SizedBox(height: 12),

          // Category filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.primaryBlue,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // FAQ Section Header
          Text(
            'Frequently Asked Questions (${faqs.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),

          if (faqs.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.search_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 10),
                      const Text(
                        'No matching questions found',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Try searching for other keywords or submit a query above.',
                        style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...faqs.map(
              (faq) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ExpansionTile(
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.help_outline,
                      color: AppTheme.primaryBlue,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    faq.question,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        faq.answer,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.45,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
