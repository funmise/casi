import 'package:casi/core/error/exceptions.dart';
import 'package:casi/core/user/data/models/clinic_model.dart';
import 'package:casi/core/user/data/models/enrollment_model.dart';
import 'package:casi/core/user/data/models/user_model.dart';
import 'package:casi/core/user/data/models/user_profile_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:rxdart/rxdart.dart';

abstract interface class UserRemoteDataSource {
  /// Emits a fully composed UserProfile or null while signed out.
  Stream<UserProfileModel?> watch();
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final fa.FirebaseAuth _auth;
  final FirebaseFirestore _db;

  UserRemoteDataSourceImpl({
    required fa.FirebaseAuth auth,
    required FirebaseFirestore db,
  }) : _auth = auth,
       _db = db;

  // ---------------- helpers ----------------
  CollectionReference<Map<String, dynamic>> _userEnrollments(String uid) =>
      _db.collection('users').doc(uid).collection('enrollments');

  // ---------------- API ----------------
  @override
  Stream<UserProfileModel?> watch() {
    try {
      return _auth
          .authStateChanges()
          .switchMap((fa.User? user) {
            if (user == null) {
              return Stream<UserProfileModel?>.value(null);
            }
            final base = UserModel.fromFirebaseUser(user);

            // --- Enrollment stream (model, fromCache)
            final enrollment$ = _userEnrollments(user.uid)
                .orderBy('createdAt', descending: true)
                .limit(1)
                .snapshots(includeMetadataChanges: true)
                .map((qs) {
                  final fromCache = qs.metadata.isFromCache;
                  if (qs.docs.isEmpty) {
                    return (
                      model: EnrollmentModel.empty(),
                      fromCache: fromCache,
                    );
                  }
                  final model = EnrollmentModel.fromDoc(qs.docs.first);
                  return (model: model, fromCache: fromCache);
                })
                .handleError((e) {
                  throw ServerException('Failed to fetch enrollment: $e');
                });

            // --- Clinic stream depends on enrollment; also (model, fromCache)
            final clinic$ = enrollment$.switchMap((enr) {
              final clinicId = enr.model.clinicId;
              if (clinicId.isEmpty) {
                return Stream<({ClinicModel model, bool fromCache})>.value((
                  model: ClinicModel.empty(),
                  fromCache: false,
                ));
              }
              return _db
                  .collection('clinics')
                  .doc(clinicId)
                  .snapshots(includeMetadataChanges: true)
                  .map((snap) {
                    final model = snap.exists
                        ? ClinicModel.fromDoc(snap)
                        : ClinicModel.empty();
                    final fromCache = snap.metadata.isFromCache;
                    return (model: model, fromCache: fromCache);
                  })
                  .handleError((e) {
                    throw ServerException('Failed to fetch clinic: $e');
                  });
            });

            // --- Combine both and compute a single fromCache flag
            return Rx.combineLatest2(enrollment$, clinic$, (enr, cl) {
              final enrollment = enr.model;
              final clinic = cl.model;
              final fromCache = enr.fromCache || cl.fromCache;

              return UserProfileModel(
                uid: base.id,
                email: base.email,
                name: base.name,
                userCreatedAt: base.createdAt,
                enrollmentStatus: enrollment.status,
                ethicsVersion: enrollment.ethicsVersion,
                ethicsAcceptedAt: enrollment.ethicsAcceptedAt,
                clinicId: enrollment.clinicId.isEmpty
                    ? null
                    : enrollment.clinicId,
                clinicName: clinic.name.isEmpty ? null : clinic.name,
                clinicProvince: clinic.province,
                clinicCity: clinic.city,
                clinicStatus: clinic.status,
                fromCache: fromCache,
              );
            }).handleError((e) {
              throw ServerException('Failed to combine user profile: $e');
            });
          })
          .handleError((e) {
            throw ServerException('Auth state stream error: $e');
          });
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Unexpected error in User.watch: $e');
    }
  }
}
