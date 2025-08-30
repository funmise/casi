import 'package:casi/features/survey/data/models/survey_page_model.dart';
import 'package:casi/features/survey/domain/entities/survey_template.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SurveyTemplateModel extends SurveyTemplate {
  const SurveyTemplateModel({
    required super.version,
    required super.title,
    required super.subtitle,
    required super.order,
    required super.updatedAt,
    super.pages = const [],
  });

  factory SurveyTemplateModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> d,
  ) {
    final data = d.data() ?? {};
    final List<dynamic> ord = (data['order'] as List?) ?? const [];
    DateTime dateTime(dynamic v) =>
        v is Timestamp ? v.toDate() : DateTime.now();

    return SurveyTemplateModel(
      version: d.id,
      title: data['title'] as String? ?? 'Survey',
      subtitle: data['subtitle'] as String? ?? '',
      order: ord.map((e) => e.toString()).toList(),
      updatedAt: dateTime(data['updatedAt']),
    );
  }

  SurveyTemplateModel copyWith({List<SurveyPageModel>? pages}) =>
      SurveyTemplateModel(
        version: version,
        title: title,
        subtitle: subtitle,
        order: order,
        updatedAt: updatedAt,
        pages: pages ?? this.pages,
      );
}
