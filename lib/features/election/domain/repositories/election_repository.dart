import '../entities/election.dart';

abstract class ElectionRepository {
  Future<Election?> getActiveElection(String currentUserId);

  Future<void> nominateSelf({
    required String electionId,
    required String candidateId,
    required String candidateName,
    required String manifesto,
  });

  Future<void> castVote({
    required String electionId,
    required String voterId,
    required String candidateId,
  });
}
