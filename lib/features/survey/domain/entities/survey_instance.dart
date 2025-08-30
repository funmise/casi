class SurveyInstance {
  final String quarterId;
  final DateTime opensAt;
  final DateTime closesAt;
  final String templateVersion;
  final bool isActive;
  final DateTime updatedAt;

  const SurveyInstance({
    required this.quarterId,
    required this.opensAt,
    required this.closesAt,
    required this.templateVersion,
    required this.isActive,
    required this.updatedAt,
  });
}
