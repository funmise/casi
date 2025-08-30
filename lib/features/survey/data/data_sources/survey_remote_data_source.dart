import 'package:casi/features/survey/data/models/survey_instance_model.dart';
import 'package:casi/features/survey/data/models/survey_page_model.dart';
import 'package:casi/features/survey/data/models/survey_template_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:casi/core/error/exceptions.dart';
import 'package:casi/features/survey/data/models/user_survey_model.dart';

abstract interface class SurveyRemoteDataSource {
  Future<SurveyInstanceModel> getActiveInstance();
  Future<SurveyTemplateModel> getTemplate(String versionId);
  Future<UserSurveyModel?> getUserSubmission({
    required String uid,
    required String quarterId,
  });

  Future<void> saveDraft({
    required String uid,
    required String quarterId,
    required String templateVersion,
    required Map<String, dynamic> answers,
  });

  Future<void> submit({
    required String uid,
    required String quarterId,
    required String templateVersion,
    required Map<String, dynamic> answers,
  });
}

class SurveyRemoteDataSourceImpl implements SurveyRemoteDataSource {
  final FirebaseFirestore _db;
  SurveyRemoteDataSourceImpl(this._db);

  @override
  Future<SurveyInstanceModel> getActiveInstance() async {
    try {
      // Prefer an active instance that is currently not closed.
      final now = Timestamp.now();
      final q = await _db
          .collection('survey_instances')
          .where('isActive', isEqualTo: true)
          .orderBy('closesAt')
          .where('closesAt', isGreaterThanOrEqualTo: now)
          .limit(1)
          .get();

      if (q.docs.isNotEmpty) {
        return SurveyInstanceModel.fromDoc(q.docs.first);
      }

      // Fallback: opensAt (in case closeAt dates weren’t set strictly).
      final q2 = await _db
          .collection('survey_instances')
          .where('isActive', isEqualTo: true)
          .orderBy('opensAt', descending: true)
          .limit(1)
          .get();

      if (q2.docs.isEmpty) {
        throw ServerException('active-survey-not-found');
      }
      return SurveyInstanceModel.fromDoc(q2.docs.first);
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Firestore error while loading active survey instance.',
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<SurveyTemplateModel> getTemplate(String versionId) async {
    try {
      final root = await _db
          .collection('survey_templates')
          .doc(versionId)
          .get();
      if (!root.exists) throw ServerException('survey-template-not-found');

      final template = SurveyTemplateModel.fromDoc(root);

      // Page list is defined by order[] in the template doc.
      final List<SurveyPageModel> pages = [];
      for (final pid in template.order) {
        final pdoc = await _db
            .collection('survey_templates')
            .doc(versionId)
            .collection('pages')
            .doc(pid)
            .get();
        if (!pdoc.exists) continue; // skip silently
        pages.add(SurveyPageModel.fromDoc(pdoc, idOverride: pid));
      }

      return template.copyWith(pages: pages);
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Firestore error while loading template.',
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserSurveyModel?> getUserSubmission({
    required String uid,
    required String quarterId,
  }) async {
    try {
      final ref = _db
          .collection('users')
          .doc(uid)
          .collection('surveys')
          .doc(quarterId);
      final doc = await ref.get();
      if (!doc.exists) return null;
      return UserSurveyModel.fromDoc(doc);
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Firestore error while loading user survey.',
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> saveDraft({
    required String uid,
    required String quarterId,
    required String templateVersion,
    required Map<String, dynamic> answers,
  }) async {
    try {
      final ref = _db
          .collection('users')
          .doc(uid)
          .collection('surveys')
          .doc(quarterId);
      await ref.set({
        'quarterId': quarterId,
        'templateVersion': templateVersion,
        'status': 'draft',
        'answers': answers,
        'savedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Firestore error while saving draft.');
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> submit({
    required String uid,
    required String quarterId,
    required String templateVersion,
    required Map<String, dynamic> answers,
  }) async {
    try {
      final ref = _db
          .collection('users')
          .doc(uid)
          .collection('surveys')
          .doc(quarterId);
      await ref.set({
        'quarterId': quarterId,
        'templateVersion': templateVersion,
        'status': 'submitted',
        'answers': answers,
        'savedAt': FieldValue.serverTimestamp(),
        'submittedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Firestore error while submitting survey.',
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
