import 'package:casi/core/consts.dart';
import 'package:casi/features/survey/domain/entities/user_survey.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserSurveyModel extends UserSurvey {
  const UserSurveyModel({
    required super.quarterId,
    required super.templateVersion,
    required super.status,
    required super.answers,
    super.currentIndex,
    super.savedAt,
    super.submittedAt,
  });

  factory UserSurveyModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data() ?? {};
    DateTime? dateTime(dynamic v) => v is Timestamp ? v.toDate() : null;

    return UserSurveyModel(
      quarterId: data['quarterId']?.toString() ?? d.id,
      templateVersion: data['templateVersion']?.toString() ?? kTemplateVersion,
      status: data['status']?.toString() ?? 'draft',
      answers:
          (data['answers'] as Map?)?.map((k, v) => MapEntry(k.toString(), v)) ??
          <String, dynamic>{},
      currentIndex: (data['currentIndex'] is num)
          ? (data['currentIndex'] as num).toInt()
          : null,
      savedAt: dateTime(data['savedAt']),
      submittedAt: dateTime(data['submittedAt']),
    );
  }
}
