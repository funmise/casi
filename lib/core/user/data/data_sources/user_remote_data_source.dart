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

            // enrollment stream
            final enrollment$ = _db
                .collection('enrollments')
                .doc(user.uid)
                .snapshots()
                .map((enrollmentDoc) {
                  if (!enrollmentDoc.exists) return EnrollmentModel.empty();
                  return EnrollmentModel.fromDoc(enrollmentDoc);
                })
                .handleError((e) {
                  throw ServerException('Failed to fetch enrollment: $e');
                });

            // clinic stream
            final clinic$ = enrollment$.switchMap((enrollment) {
              if (enrollment.clinicId.isEmpty) {
                return Stream<ClinicModel>.value(ClinicModel.empty());
              }
              return _db
                  .collection('clinics')
                  .doc(enrollment.clinicId)
                  .snapshots()
                  .map((clinicDoc) {
                    if (!clinicDoc.exists) return ClinicModel.empty();
                    return ClinicModel.fromDoc(clinicDoc);
                  })
                  .handleError((e) {
                    throw ServerException('Failed to fetch clinic: $e');
                  });
            });

            // combine enrollment + clinic into domain entity
            return Rx.combineLatest2(enrollment$, clinic$, (
              enrollment,
              clinic,
            ) {
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
