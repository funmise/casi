import 'package:casi/features/survey/domain/entities/input_config.dart';

class SurveyPage {
  final String id;
  final String kind; // "pathogen"|"diagnostic"|"notes"|...
  final String title;
  final List<InputConfig> inputs;

  const SurveyPage({
    required this.id,
    required this.kind,
    required this.title,
    required this.inputs,
  });
}
