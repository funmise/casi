import 'package:casi/features/survey/data/models/input_config_model.dart';
import 'package:casi/features/survey/domain/entities/survey_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SurveyPageModel extends SurveyPage {
  const SurveyPageModel({
    required super.id,
    required super.kind,
    required super.title,
    required super.inputs,
  });

  factory SurveyPageModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> d, {
    String? idOverride,
  }) {
    final data = d.data() ?? {};
    final inputsRaw = (data['inputs'] as List?) ?? const [];
    return SurveyPageModel(
      id: idOverride ?? d.id,
      kind: (data['kind']?.toString() ?? '').toLowerCase(),
      title: data['title']?.toString() ?? '',
      inputs: inputsRaw
          .whereType<Map>()
          .map(
            (m) => InputConfigModel.fromMap(
              m.map((k, v) => MapEntry(k.toString(), v)),
            ),
          )
          .toList(),
    );
  }
}
