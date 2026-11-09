import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../../shared/widgets/app_top_bar_actions.dart';
import '../../domain/entities/election.dart';
import '../providers/election_provider.dart';

class ElectionsScreen extends ConsumerStatefulWidget {
  final AuthUser currentUser;

  const ElectionsScreen({super.key, required this.currentUser});

  @override
  ConsumerState<ElectionsScreen> createState() => _ElectionsScreenState();
}

class _ElectionsScreenState extends ConsumerState<ElectionsScreen> {
  Election? _election;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadElection();
  }

  Future<void> _loadElection() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(electionRepositoryProvider);
      final election = await repo.getActiveElection(widget.currentUser.uid);
      if (!mounted) return;
      setState(() {
        _election = election;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showNominateDialog() async {
    final election = _election;
    if (election == null) return;
    final manifestoCtrl = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Nomination'),
        content: TextField(
          key: const Key('manifesto_input'),
          controller: manifestoCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Your Election Manifesto / Vision',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('submit_nomination_button'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Submit Nomination'),
          ),
        ],
      ),
    );

    if (submitted == true && manifestoCtrl.text.trim().isNotEmpty) {
      await ref.read(electionRepositoryProvider).nominateSelf(
            electionId: election.id,
            candidateId: widget.currentUser.uid,
            candidateName: widget.currentUser.fullName,
            manifesto: manifestoCtrl.text.trim(),
          );
      await _loadElection();
    }
  }

  Future<void> _castVote(String candidateId) async {
    final election = _election;
    if (election == null || election.hasVoted) return;

    await ref.read(electionRepositoryProvider).castVote(
          electionId: election.id,
          voterId: widget.currentUser.uid,
          candidateId: candidateId,
        );
    await _loadElection();
  }

  @override
  Widget build(BuildContext context) {
    final election = _election;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Governance & Elections'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: const [
          AppTopBarActions(),
        ],
      ),
      floatingActionButton: election != null
          ? FloatingActionButton.extended(
              key: const Key('nominate_self_button'),
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              onPressed: _showNominateDialog,
              icon: const Icon(Icons.how_to_vote),
              label: const Text('Nominate Self'),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : election == null
              ? const Center(child: Text('No active elections at this time.'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              election.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(election.description),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Official Candidates',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...election.candidates.map((cand) {
                      final isVotedCandidate =
                          election.votedCandidateId == cand.id;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      cand.candidateName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Chip(
                                    label: Text('${cand.voteCount} votes'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(cand.manifesto),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: isVotedCandidate
                                    ? const Chip(
                                        avatar: Icon(
                                          Icons.check_circle,
                                          color: AppTheme.successGreen,
                                          size: 18,
                                        ),
                                        label: Text('Voted'),
                                      )
                                    : ElevatedButton.icon(
                                        key: Key('vote_button_${cand.id}'),
                                        onPressed: election.hasVoted
                                            ? null
                                            : () => _castVote(cand.id),
                                        icon: const Icon(Icons.how_to_vote),
                                        label: const Text('Vote'),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
    );
  }
}
