class ElectionCandidate {
  final String id;
  final String candidateId;
  final String candidateName;
  final String manifesto;
  final int voteCount;

  const ElectionCandidate({
    required this.id,
    required this.candidateId,
    required this.candidateName,
    required this.manifesto,
    this.voteCount = 0,
  });

  ElectionCandidate copyWith({int? voteCount}) {
    return ElectionCandidate(
      id: id,
      candidateId: candidateId,
      candidateName: candidateName,
      manifesto: manifesto,
      voteCount: voteCount ?? this.voteCount,
    );
  }

  factory ElectionCandidate.fromMap(Map<String, dynamic> map, {String? docId}) {
    return ElectionCandidate(
      id: (docId ?? map['id'] ?? '').toString(),
      candidateId: (map['candidateId'] ?? map['candidate_id'] ?? '').toString(),
      candidateName:
          (map['candidateName'] ?? map['candidate_name'] ?? 'Candidate')
              .toString(),
      manifesto: (map['manifesto'] ?? '').toString(),
      voteCount: (map['voteCount'] ?? map['vote_count'] ?? 0) is int
          ? (map['voteCount'] ?? map['vote_count'] ?? 0) as int
          : int.tryParse(
                  (map['voteCount'] ?? map['vote_count'] ?? '0').toString(),
                ) ??
                0,
    );
  }
}

class Election {
  final String id;
  final String title;
  final String description;
  final String status;
  final List<ElectionCandidate> candidates;
  final String? votedCandidateId;

  const Election({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.candidates,
    this.votedCandidateId,
  });

  bool get hasVoted => votedCandidateId != null && votedCandidateId!.isNotEmpty;

  Election copyWith({
    List<ElectionCandidate>? candidates,
    String? votedCandidateId,
  }) {
    return Election(
      id: id,
      title: title,
      description: description,
      status: status,
      candidates: candidates ?? this.candidates,
      votedCandidateId: votedCandidateId ?? this.votedCandidateId,
    );
  }
}
