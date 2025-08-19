import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:casi/core/error/exceptions.dart';
import 'package:casi/core/user/data/models/clinic_model.dart';
import 'package:casi/core/user/data/models/enrollment_model.dart';
import 'package:casi/features/enrollment/data/models/ethics_model.dart';

abstract interface class EnrollmentRemoteDataSource {
  Future<List<ClinicModel>> queryClinicsPrefix(String q, {int? limit});
  Future<ClinicModel> createPendingClinic(
    String name, {
    String? province,
    String? city,
  });
  setEnrollmentClinic({
    required String uid,
    required String clinicId,
    int? avgDogsPerWeek,
  });
  Future<EnrollmentModel> getEnrollment(String uid);
  Future<EthicsModel> getActiveEthics();
  Future<void> acceptEthics({required String uid, required String version});
}

class EnrollmentRemoteDataSourceImpl implements EnrollmentRemoteDataSource {
  final FirebaseFirestore _db;
  EnrollmentRemoteDataSourceImpl(this._db);

  @override
  Future<List<ClinicModel>> queryClinicsPrefix(String q, {int? limit}) async {
    try {
      if (q.isEmpty) return [];
      final qLower = q.toLowerCase();

      var query = _db
          .collection('clinics')
          .where('status', isEqualTo: 'active') // show only active in typeahead
          .orderBy('nameLower')
          .startAt([qLower])
          .endAt(['$qLower\uf8ff']);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snap = await query.get();
      return snap.docs.map((d) => ClinicModel.fromDoc(d)).toList();
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Firestore error while querying clinics.',
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ClinicModel> createPendingClinic(
    String name, {
    String? province,
    String? city,
  }) async {
    try {
      final ref = await _db.collection('clinics').add({
        'name': name,
        'nameLower': name.toLowerCase(),
        'province': province,
        'city': city,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      final doc = await ref.get();
      return ClinicModel.fromDoc(doc);
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Firestore error while creating clinic.',
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> setEnrollmentClinic({
    required String uid,
    required String clinicId,
    int? avgDogsPerWeek,
  }) async {
    try {
      await _db.collection('enrollments').doc(uid).set({
        'clinicId': clinicId,
        'status': 'awaitingEthics',
        if (avgDogsPerWeek != null) 'avgDogsPerWeek': avgDogsPerWeek,
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Firestore error while setting enrollment clinic.',
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<EnrollmentModel> getEnrollment(String uid) async {
    try {
      final doc = await _db.collection('enrollments').doc(uid).get();
      if (!doc.exists) {
        throw ServerException('enrollment-not-found');
      }
      return EnrollmentModel.fromDoc(doc);
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Firestore error while fetching enrollment.',
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<EthicsModel> getActiveEthics() async {
    try {
      final snap = await _db
          .collection('ethics_versions')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        throw ServerException('No active ethics/terms found.');
      }
      return EthicsModel.fromDoc(snap.docs.first);
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Firestore error while loading ethics.',
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> acceptEthics({
    required String uid,
    required String version,
  }) async {
    try {
      await _db.collection('enrollments').doc(uid).set({
        'ethicsVersion': version,
        'ethicsAcceptedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Firestore error while accepting ethics.',
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
