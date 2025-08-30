import 'package:casi/core/consts.dart';
import 'package:casi/features/survey/domain/entities/survey_instance.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SurveyInstanceModel extends SurveyInstance {
  const SurveyInstanceModel({
    required super.quarterId,
    required super.opensAt,
    required super.closesAt,
    required super.templateVersion,
    required super.isActive,
    required super.updatedAt,
  });

  factory SurveyInstanceModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> d,
  ) {
    final data = d.data() ?? {};
    DateTime dateTime(dynamic v) =>
        v is Timestamp ? v.toDate() : DateTime.now();

    return SurveyInstanceModel(
      quarterId: data['quarter'] as String? ?? d.id,
      opensAt: dateTime(data['opensAt']),
      closesAt: dateTime(data['closesAt']),
      templateVersion: data['templateVersion'] as String? ?? kTemplateVersion,
      isActive: (data['isActive'] as bool?) ?? false,
      updatedAt: dateTime(data['updatedAt']),
    );
  }
}
