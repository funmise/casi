import 'package:fpdart/fpdart.dart';
import 'package:casi/core/error/failures.dart';
import 'package:casi/core/user/domain/entities/clinic.dart';
import 'package:casi/core/user/domain/entities/enrollment.dart';
import 'package:casi/features/enrollment/domain/entities/ethics.dart';

abstract interface class EnrollmentRepository {
  Future<Either<Failure, List<Clinic>>> queryClinicsPrefix(
    String q, {
    int? limit,
  });

  /// Creates a **pending** clinic (admin can flip to active later).
  Future<Either<Failure, Clinic>> createPendingClinic(
    String name, {
    String? province,
    String? city,
  });

  /// Create or update the user's enrollment with the chosen clinic.
  Future<Either<Failure, void>> setEnrollmentClinic({
    required String uid,
    required String clinicId,
    int? avgDogsPerWeek,
  });

  Future<Either<Failure, Enrollment>> getEnrollment(String uid);

  /// Returns the one active ethics/ToS document.
  Future<Either<Failure, Ethics>> getActiveEthics();

  /// Marks ethics accepted and **activates** the enrollment regardless of clinic status.
  Future<Either<Failure, void>> acceptEthics({
    required String uid,
    required String version,
  });
}
