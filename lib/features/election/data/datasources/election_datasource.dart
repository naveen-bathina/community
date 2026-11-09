import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/election.dart';
import '../../domain/repositories/election_repository.dart';

class FirebaseElectionRepository implements ElectionRepository {
  final FirebaseFirestore _firestore;

  FirebaseElectionRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Election?> getActiveElection(String currentUserId) async {
    final snap = await _firestore.collection('elections').limit(1).get();
    if (snap.docs.isEmpty) {
      return _defaultElection();
    }
    final doc = snap.docs.first;
    final data = doc.data();
    final nomSnap = await doc.reference.collection('nominations').get();
    final voteDoc = await doc.reference
        .collection('votes')
        .doc(currentUserId)
        .get();

    final candidates = nomSnap.docs
        .map((d) => ElectionCandidate.fromMap(d.data(), docId: d.id))
        .toList();

    return Election(
      id: doc.id,
      title: (data['title'] ?? 'Bar Council Executive Election').toString(),
      description: (data['description'] ?? '').toString(),
      status: (data['status'] ?? 'voting_open').toString(),
      candidates: candidates,
      votedCandidateId: voteDoc.exists
          ? (voteDoc.data()?['candidateId'] as String?)
          : null,
    );
  }

  @override
  Future<void> nominateSelf({
    required String electionId,
    required String candidateId,
    required String candidateName,
    required String manifesto,
  }) async {
    final elecRef = _firestore.collection('elections').doc(electionId);
    final elecDoc = await elecRef.get();
    if (!elecDoc.exists) {
      await elecRef.set({
        'title': 'Bar Council Executive Committee Election 2026',
        'description':
            'Annual democratic election for community moderators and officers.',
        'status': 'voting_open',
      });
    }
    await elecRef.collection('nominations').doc(candidateId).set({
      'candidateId': candidateId,
      'candidateName': candidateName,
      'manifesto': manifesto.trim(),
      'voteCount': 0,
    });
  }

  @override
  Future<void> castVote({
    required String electionId,
    required String voterId,
    required String candidateId,
  }) async {
    final elecRef = _firestore.collection('elections').doc(electionId);
    final voteRef = elecRef.collection('votes').doc(voterId);
    final nomRef = elecRef.collection('nominations').doc(candidateId);

    await _firestore.runTransaction((tx) async {
      final existingVote = await tx.get(voteRef);
      if (existingVote.exists) return;
      tx.set(voteRef, {
        'voterId': voterId,
        'candidateId': candidateId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.set(nomRef, {
        'voteCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
    });
  }

  Election _defaultElection() {
    return const Election(
      id: 'elec-2026',
      title: 'Bar Council Executive Committee Election 2026',
      description:
          'Annual democratic election for community moderators and officers.',
      status: 'voting_open',
      candidates: [],
    );
  }
}

class SupabaseElectionRepository implements ElectionRepository {
  final SupabaseClient _supabase;

  SupabaseElectionRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  @override
  Future<Election?> getActiveElection(String currentUserId) async {
    final rows = await _supabase.from('elections').select().limit(1);
    if ((rows as List).isEmpty) {
      return const Election(
        id: 'elec-2026',
        title: 'Bar Council Executive Committee Election 2026',
        description:
            'Annual democratic election for community moderators and officers.',
        status: 'voting_open',
        candidates: [],
      );
    }
    final electionRow = Map<String, dynamic>.from(rows.first);
    final electionId = electionRow['id'].toString();

    final nomRows = await _supabase
        .from('nominations')
        .select()
        .eq('election_id', electionId);
    final voteRows = await _supabase
        .from('votes')
        .select()
        .eq('election_id', electionId);

    final counts = <String, int>{};
    String? votedCandId;
    for (final v in (voteRows as List)) {
      final nomId = v['nomination_id'].toString();
      counts[nomId] = (counts[nomId] ?? 0) + 1;
      if (v['voter_id'].toString() == currentUserId) {
        votedCandId = nomId;
      }
    }

    final candidates = (nomRows as List).map((n) {
      final map = Map<String, dynamic>.from(n);
      final id = map['id'].toString();
      return ElectionCandidate(
        id: id,
        candidateId: (map['candidate_id'] ?? '').toString(),
        candidateName: (map['candidate_name'] ?? 'Advocate').toString(),
        manifesto: (map['manifesto'] ?? '').toString(),
        voteCount: counts[id] ?? 0,
      );
    }).toList();

    return Election(
      id: electionId,
      title: (electionRow['title'] ?? 'Bar Council Election').toString(),
      description: (electionRow['description'] ?? '').toString(),
      status: (electionRow['status'] ?? 'voting_open').toString(),
      candidates: candidates,
      votedCandidateId: votedCandId,
    );
  }

  @override
  Future<void> nominateSelf({
    required String electionId,
    required String candidateId,
    required String candidateName,
    required String manifesto,
  }) async {
    await _supabase.from('nominations').upsert({
      'election_id': electionId,
      'candidate_id': candidateId,
      'manifesto': manifesto.trim(),
      'status': 'approved',
    });
  }

  @override
  Future<void> castVote({
    required String electionId,
    required String voterId,
    required String candidateId,
  }) async {
    await _supabase.from('votes').insert({
      'election_id': electionId,
      'nomination_id': candidateId,
      'voter_id': voterId,
    });
  }
}

class InMemoryElectionRepository implements ElectionRepository {
  Election _election = const Election(
    id: 'elec-2026',
    title: 'Bar Council Executive Committee Election 2026',
    description:
        'Annual democratic election for community moderators and officers.',
    status: 'voting_open',
    candidates: [
      ElectionCandidate(
        id: 'cand-1',
        candidateId: 'u-101',
        candidateName: 'Adv. Priya Sharma',
        manifesto:
            'Transparent digital referrals & mentorship for junior counsel.',
        voteCount: 14,
      ),
      ElectionCandidate(
        id: 'cand-2',
        candidateId: 'u-102',
        candidateName: 'Adv. Rajesh Verma',
        manifesto:
            'Stronger state bar coordination and pro-bono legal aid cells.',
        voteCount: 11,
      ),
    ],
  );

  @override
  Future<Election?> getActiveElection(String currentUserId) async => _election;

  @override
  Future<void> nominateSelf({
    required String electionId,
    required String candidateId,
    required String candidateName,
    required String manifesto,
  }) async {
    _election = _election.copyWith(
      candidates: [
        ..._election.candidates,
        ElectionCandidate(
          id: 'cand-${_election.candidates.length + 1}',
          candidateId: candidateId,
          candidateName: candidateName,
          manifesto: manifesto,
          voteCount: 0,
        ),
      ],
    );
  }

  @override
  Future<void> castVote({
    required String electionId,
    required String voterId,
    required String candidateId,
  }) async {
    if (_election.hasVoted) return;
    _election = _election.copyWith(
      votedCandidateId: candidateId,
      candidates: _election.candidates.map((c) {
        if (c.id == candidateId) {
          return c.copyWith(voteCount: c.voteCount + 1);
        }
        return c;
      }).toList(),
    );
  }
}
