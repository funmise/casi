import 'package:casi/features/survey/domain/entities/survey_page.dart';

class SurveyTemplate {
  final String version;
  final String title;
  final String subtitle;
  final List<String> order;
  final DateTime updatedAt;

  // Filled in by data layer when pages are fetched.
  final List<SurveyPage> pages;

  const SurveyTemplate({
    required this.version,
    required this.title,
    required this.subtitle,
    required this.order,
    required this.updatedAt,
    this.pages = const [],
  });
}
