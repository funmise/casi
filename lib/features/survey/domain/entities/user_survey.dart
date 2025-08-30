class UserSurvey {
  final String quarterId;
  final String templateVersion;
  final String status; // "draft"|"submitted"
  final Map<String, dynamic> answers;
  final DateTime? savedAt;
  final DateTime? submittedAt;

  const UserSurvey({
    required this.quarterId,
    required this.templateVersion,
    required this.status,
    required this.answers,
    this.savedAt,
    this.submittedAt,
  });
}
